{ config, pkgs, lib, ... }:
  let
    cfg = config.services.remotehiro;
    exe = lib.getExe cfg.package;
    migratorExe = lib.getExe cfg.migratorPackage;
  in with lib; {
    options = {
      services.remotehiro = {
        enable = mkOption {
          default = false;
          type = with types; bool;
          description = "Start the remotehiro server for a user";
        };

        package = lib.mkPackageOption pkgs "remotehiro" { };
        migratorPackage = lib.mkPackageOption pkgs "remotehiro-migrator" {};

        port = mkOption {
          default = "3000";
          type = with types; str;
          description = "Port number remotehiro will run on";
        };

        stateDir = mkOption {
          type = types.path;
          description = "Path to data directory. This is where the database will be stored.";
          default = "/var/lib/remotehiro";
        };

        databaseName = mkOption {
          type = types.str;
          description = "Database file name in the data directory.";
          default = "remotehiro.db";
        };

        user = mkOption {
          type = types.str;
          description = "User account under which remotehiro runs.";
          default = "remotehiro";
        };

        group = mkOption {
          type = types.str;
          description = "Group under which remotehiro runs.";
          default = "remotehiro";
        };
      };
    };

    config = mkIf cfg.enable {
      systemd.services.remotehiro = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        description = "Start the remotehiro server";

        environment = mkMerge [
          {
            REMOTEHIRO_DATABASE_PATH = "${cfg.stateDir}/remotehiro.db";
            REMOTEHIRO_WAREHOUSE_DATABASE_PATH = "${cfg.stateDir}/warehouse.db";
            REMOTEHIRO_CURRENCY_EXCHANGE_DATABASE_PATH = "${cfg.stateDir}/eurofxref-hist.db3";
            REMOTEHIRO_SERVER_PORT = "${cfg.port}";
            USER = cfg.user;
            HOME = cfg.stateDir;
          }
        ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${exe}";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.stateDir;
          Restart = "always";

          # Runtime directory and mode
          RuntimeDirectory = "remotehiro";
          RuntimeDirectoryMode = "0755";

          ReadWritePaths = [
            cfg.stateDir
          ];

          UMask = "0027";

          ProtectProc = "invisible";
          NoNewPrivileges = true;

          # Sandboxing
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateUsers = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
        };

        preStart = ''
          if [ ! -f migrations.db ]; then
            ${migratorExe} init
          fi

          ${migratorExe} migrations up
          ${migratorExe} data-migrations up
          ${migratorExe} warehouse-migrations up
        '';
      };

      users.users = mkIf (cfg.user == "remotehiro") {
        remotehiro = {
          home = cfg.stateDir;
          useDefaultShell = true;
          group = cfg.group;
          isSystemUser = true;
          createHome = true;
        };
      };

      users.groups = mkIf (cfg.group == "remotehiro") {
        remotehiro = {};
      };

      environment.systemPackages = [ cfg.package cfg.migratorPackage ];
      systemd.packages = [ cfg.package cfg.migratorPackage ];
    };
  }
