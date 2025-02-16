{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    git-hooks.url = "github:cachix/git-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    crane.url = "github:ipetkov/crane";

    fenix = {
      url = "github:nix-community/fenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-analyzer-src.follows = "";
      };
    };

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };

    moneyman-flake = {
      url = "github:tacohirosystems/moneyman";
    };

    tacopkgs = {
      url = "git+https://forgejo.quoll-owl.ts.net/tacohirosystems/tacopkgs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
      };
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , moneyman-flake
    , tacopkgs
    , git-hooks
    , flake-parts
    , crane
    , fenix
    , advisory-db
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      imports = [ ];

      flake = {
        nixosModules = {
          default = import ./nix/modules/remotehiro.nix;
          remotehiro = import ./nix/modules/remotehiro.nix;
          remotehiro-moneyman = import ./nix/modules/moneyman.nix;
          remotehiro-warehouse = import ./nix/modules/remotehiro-warehouse.nix;
        };
      };

      perSystem = { config, system, ... }:
        let
          version = "0.0.1-alpha";
          server_port = "3000";
          overlays = [ ];
          pkgs = import nixpkgs { inherit system overlays; config.allowUnfree = true; };
          pkgs-unstable = import nixpkgs-unstable { inherit system overlays; };

          craneLib = (crane.mkLib pkgs).overrideToolchain
            fenix.packages.${system}.stable.toolchain;

          src = pkgs.lib.cleanSourceWith {
            src = ./.;

            filter = path: type:
              (pkgs.lib.hasSuffix "\.css" path) ||
              (pkgs.lib.hasSuffix "\.js" path) ||
              (pkgs.lib.hasSuffix "\.html" path) ||
              (pkgs.lib.hasSuffix "\.webp" path) ||
              (pkgs.lib.hasSuffix "VERSION" path) ||
              (pkgs.lib.hasSuffix "\.sql" path) ||
              (pkgs.lib.hasInfix "/assets/" path) ||
              (pkgs.lib.hasInfix "/templates/" path) ||
              (craneLib.filterCargoSources path type)
            ;
          };

          # Common arguments can be set here to avoid repeating them later
          commonArgs = rec {
            inherit src;
            inherit version;
            strictDeps = true;
            pname = "remotehiro";
            name = "remotehiro";

            SQLITE3_LIB_DIR = "${pkgs-unstable.lib.makeLibraryPath [ pkgs-unstable.sqlite ]}";
            SQLITE3_INCLUDE_DIR = "${pkgs-unstable.sqlite.dev}/include";
            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
            BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/19/include";

            buildInputs = [
              pkgs.openssl
              pkgs-unstable.sqlite.dev
              pkgs-unstable.sqlite
              pkgs.libclang.lib
            ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
              libiconv
              darwin.apple_sdk.frameworks.CoreFoundation
              darwin.apple_sdk.frameworks.CoreServices
              darwin.apple_sdk.frameworks.Security
              darwin.apple_sdk.frameworks.SystemConfiguration
            ]) ++ pkgs.lib.optionals pkgs.stdenv.isLinux (with pkgs; [
            ]);

            nativeBuildInputs = with pkgs; [
              pkg-config
              esbuild
              git
              pkgs.autoPatchelfHook
            ];
          };

          cargoArtifacts = craneLib.buildDepsOnly commonArgs;

          mkRemoteHiro = profile: craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts;
            doCheck = false;
            CARGO_PROFILE = profile;
          });

          # mkRemoteHiroDockerImage = remotehiro: server_port: tag: pkgs.dockerTools.streamLayeredImage {
          #   inherit tag;
          #   name = "remotehiro";

          #   contents = with pkgs; [
          #     remotehiro
          #     busybox
          #   ];

          #   config = {
          #     Cmd = [ "/bin/remotehiro" "--log-format" "json" "server" ];

          #     Env = [
          #       "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          #     ];
          #   };
          # };
        in
        {
          checks = {
            mkRemoteHiro = mkRemoteHiro "test";

            # TODO: Uncomment in refactor/error branch
            remotehiro-clippy = craneLib.cargoClippy (commonArgs // {
              inherit cargoArtifacts;
              CARGO_PROFILE = "test";
              cargoClippyExtraArgs = "--all-targets -- --deny warnings";
            });

            remotehiro-doc = craneLib.cargoDoc (commonArgs // {
              inherit cargoArtifacts;
              CARGO_PROFILE = "test";
            });

            # Check formatting
            remotehiro-fmt = craneLib.cargoFmt (commonArgs // {
              inherit src;
              CARGO_PROFILE = "test";
            });

            # Audit dependencies
            remotehiro-audit = craneLib.cargoAudit {
              inherit src advisory-db;
            };

            # remotehiro-nextest = craneLib.cargoNextest (commonArgs // {
            #   inherit cargoArtifacts;

            #   partitions = 2;
            #   partitionType = "count";

            #   CARGO_PROFILE = "test";
            #   RH__DATABASE_TEST__NAME = "rh_test";
            #   RH__DATABASE_TEST__HOST = "localhost";
            #   RH__DATABASE_TEST__PORT = "5432";
            #   RH__DATABASE_TEST__USER = "rh";
            #   RH__DATABASE_TEST__PASSWORD = "rh";
            #   RH__DATABASE_TEST__POOL_SIZE = "5";
            # });

            git-hook-check = git-hooks.lib.${system}.run {
              src = ./.;

              hooks = {
                rustfmt.enable = true;
                nixpkgs-fmt.enable = true;
                # shellcheck.enable = true;
                statix.enable = true;
                taplo.enable = true;
              };
            };

            # Audit licenses
            remotehiro-deny = craneLib.cargoDeny {
              inherit src;
            };
          };

          packages =
            let
              remotehiro-unwrapped = mkRemoteHiro "release";

              remotehiro-migrator-source = import ./nix/packages/remotehiro-migrator-source.nix {
                inherit pkgs version;
              };

              remotehiro-migrator = import ./nix/packages/remotehiro-migrator.nix {
                inherit pkgs remotehiro-migrator-source;
              };

              asset-builder = import ./nix/packages/asset-builder.nix {
                inherit pkgs;
                inherit version;
              };
            in
            rec {
              default = remotehiro;
              inherit remotehiro-unwrapped;
              inherit asset-builder;
              inherit remotehiro-migrator-source;
              inherit remotehiro-migrator;

              remotehiro = import ./nix/packages/remotehiro.nix {
                remotehiro = mkRemoteHiro "release";
                inherit self;
                inherit pkgs;
                inherit version;
                inherit remotehiro-static;
              };

              remotehiro-static = import ./nix/packages/remotehiro-static.nix {
                inherit self pkgs asset-builder version;
              };
            };

          devShells = {
            ci = import ./nix/shells/ci.nix { inherit pkgs pkgs-unstable; };
            default = import ./nix/shells/dev.nix {
              inherit pkgs pkgs-unstable craneLib;
              inherit (moneyman-flake.packages.${system}) moneyman;
            };
          };
        };
    };
}
