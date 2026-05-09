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
            OnCalendar = "Mon..Fri 00:30";
            Persistent = true;
            Unit = "remotehiro-warehouse.service";
          };
      };

      systemd.services.remotehiro-warehouse = {
        script = ''
          ${pkgs.curl}/bin/curl -i --fail -X POST "${cfg.baseURL}/api/warehouse/generate" \
            -d '{"name": "JobsLocationSalariesInAltCurrencies"}' \
            -H 'Content-Type: application/json'
        '';

        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
          Group = cfg.group;

          # https://linux-audit.com/systemd/how-to-harden-a-systemd-service-unit/
          KeyringMode = "private";
          ProtectClock = true;
          ProtectHostname = true;
          ProtectKernelModules = true;
          MemoryDenyWriteExecute = true;
          RestrictNamespaces = true;
          ## Restrict service to a default set of system and network calls
          SystemCallFilter = "@system-service @network-io";

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
          CapabilityBoundingSet = "";

          # Restrict to localhost calls since this only needs to trigger a local
          # endpoint once in a while.
          IPAddressAllow = "localhost";
          IPAddressDeny = "any";
          RestrictAddressFamilies = "AF_INET";

          ProtectKernelTunables = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
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
  };
}
