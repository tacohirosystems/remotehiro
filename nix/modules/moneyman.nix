{ config, pkgs, lib, ... }:
  let
    cfg = config.services.remotehiro-moneyman;
    exe = lib.getExe cfg.package;
  in with lib; {
    options = {
      services.remotehiro-moneyman = {
        enable = mkOption {
          default = false;
          type = with types; bool;
          description = "Start the moneyman sync CRON for a user";
        };

        package = lib.mkPackageOption pkgs "moneyman" { };

        stateDir = mkOption {
          type = types.path;
          description = "Path to data directory. This is where the ECB database will be stored.";
          default = "/var/lib/remotehiro";
        };

        user = mkOption {
          type = types.str;
          description = "User account under which moneyman runs on.";
          default = "remotehiro";
        };

        group = mkOption {
          type = types.str;
          description = "Group under which moneyman runs on.";
          default = "remotehiro";
        };
      };
    };

    config = mkIf cfg.enable {
      systemd.timers."remotehiro-moneyman" = {
        wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "Mon..Fri 00:00";
            Unit = "remotehiro-moneyman.service";
          };
      };

      systemd.services.remotehiro-moneyman = {
        script = ''
          ${exe} sync --data-dir ${cfg.stateDir}
        '';

        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
          Group = cfg.group;

          WorkingDirectory = cfg.stateDir;

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

          # Prevents the service from automatically starting on rebuild. See https://discourse.nixos.org/t/how-to-prevent-custom-systemd-service-from-restarting-on-nixos-rebuild-switch/43431
          RemainAfterExit = true;
      };
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

    environment.systemPackages = [ cfg.package ];
    systemd.packages = [ cfg.package ];
  };
}
