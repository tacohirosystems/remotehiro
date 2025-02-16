{ config, pkgs, lib, ... }:
  let
    cfg = config.services.remotehiro-warehouse;
  in with lib; {
    options = {
      services.remotehiro-warehouse = {
        enable = mkOption {
          default = false;
          type = with types; bool;
          description = "Sync remotehiro warehouse's jobs_location_salaries_in_alt_currencies aggregation";
        };

        baseURL = mkOption {
          type = with types; str;
          description = "base URL of the remotehiro service. e.g http://localhost:3000";
        };

        user = mkOption {
          type = types.str;
          description = "remotehiro warehouse user";
          default = "remotehiro";
        };

        group = mkOption {
          type = types.str;
          description = "remotehiro warehouse group";
          default = "remotehiro";
        };
      };
    };

    config = mkIf cfg.enable {
      systemd.timers."remotehiro-warehouse" = {
        wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "Mon..Fri 00:05";
            Unit = "remotehiro-warehouse.service";
          };
      };

      systemd.services.remotehiro-warehouse = {
        script = ''
          ${pkgs.curl}/bin/curl -i -X POST ${cfg.baseURL}/api/warehouse/generate \
            -d '{"name": "JobsLocationSalariesInAltCurrencies"}' \
            -H 'Content-Type: application/json'
        '';

        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
          Group = cfg.group;

          # Runtime directory and mode
          # RuntimeDirectory = "remotehiro";
          # RuntimeDirectoryMode = "0755";
          ReadWritePaths = [];
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
          # RemainAfterExit = true;
      };
    };

    users.users = mkIf (cfg.user == "remotehiro") {
      remotehiro = {
        useDefaultShell = true;
        group = cfg.group;
        isSystemUser = true;
      };
    };

    users.groups = mkIf (cfg.group == "remotehiro") {
      remotehiro = {};
    };

    environment.systemPackages = [ pkgs.curl ];
    systemd.packages = [ pkgs.curl ];
  };
}
