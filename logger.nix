{ lib, pkgs, config, ...}:
with lib;
let
  cfg = config.services.necesse-server-logger;
in
{
  options.services.necesse-server-logger = {
    enable = lib.mkEnableOption "Necesse server log streaming";
    serverLogsPath = mkOption {
      type = types.str;
      description = "The path to Saved/ServerLog";
    };
    tag = mkOption {
      type = types.str;
      description = "The tag for log lines";
      default = "mt-server";
    };
  };

  config = mkIf cfg.enable {
    services.rsyslogd.extraConfig = ''
      input(type="imfile"
        File="${cfg.serverLogsPath + "/*.txt"}"
        Tag="${cfg.tag}"
        ruleset="mt-out"
        addMetadata="on"
      )
    '';
  };
}
