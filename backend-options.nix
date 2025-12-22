{ lib, config, ... }:
with lib;
let
  cfg = config;
  backendOptions = {
    enable = mkEnableOption "motortown server";
    enableLogStreaming = mkEnableOption "log streaming";
    logsTag = mkOption {
      type = types.str;
      default = "mt-server";
    };
    postInstallScript = mkOption {
      type = types.str;
      default = "";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the require ports for the game server";
    };
    port = mkOption {
      type = types.int;
      default = 14159;
    };
    user = mkOption {
      type = types.str;
      default = "steam";
      description = "The OS user that the process will run under";
    };
    stateDirectory = mkOption {
      type = types.str;
      default = "necesse-server";
      description = "The path where the server will be installed (inside /var/lib)";
    };
    environment = mkOption {
      type = types.attrsOf types.str;
      description = "The runtime environment";
      default = {};
    };
    credentialsFile = mkOption {
      type = types.path;
      description = "An environment file containing STEAM_USERNAME and STEAM_PASSWORD";
    };
    ownerName = mkOption {
      type = types.str;
      default = "owner";
      description = "The player name that will be passed as the owner of the server";
    };
  };

in {
  options = backendOptions;
}
