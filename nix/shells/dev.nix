{ pkgs, pkgs-unstable, craneLib, moneyman }: craneLib.devShell {
  # inputsFrom = [ (mkRemoteHiro "dev") self.packages.${system}.remotehiro-static ];
  # checks = self.checks.${system};

  shellHook = ''
    set -a
    source env.sh
    set +a

    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs-unstable.lib.makeLibraryPath [ pkgs-unstable.sqlite ]}"
  '';

  REMOTEHIRO_DATABASE_PATH = "remotehiro.db";
  REMOTEHIRO_WAREHOUSE_DATABASE_PATH = "warehouse.db";
  REMOTEHIRO_CURRENCY_EXCHANGE_DATABASE_PATH = "eurofxref-hist.db3";
  REMOTEHIRO_SERVER_TEMPLATES_PATH = "templates";
  REMOTEHIRO_SERVER_STATIC_ASSETS_PATH = "public";
  REMOTEHIRO_SERVER_VERSION="dev";

  SQLITE3_LIB_DIR = "${pkgs-unstable.lib.makeLibraryPath [ pkgs-unstable.sqlite ]}";
  SQLITE3_INCLUDE_DIR = "${pkgs-unstable.sqlite.dev}/include";

  LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
  BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/19/include";

  packages = with pkgs; [
    cargo-audit
    cargo-watch
    dive

    nodejs_22
    prefetch-npm-deps

    sass
    esbuild
    brotli
    gzip

    statix

    clang

    cloc

    pkg-config
    openssl

    just

    nil
    nixpkgs-fmt

    pkgs-unstable.sqlite
    pkgs-unstable.sqlite.dev
    sqitchSqlite
    sqlitebrowser

    jre8

    sqlfluff

    yamlfmt
    yamllint
    taplo
    graphicsmagick
    shellcheck
    git
    watchexec

    moneyman
  ];
}
