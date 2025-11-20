{ lib, pkgs, config, ...}:
with lib;
let
  # Paths
  steamPath = "/home/${cfg.user}/.steam/steam";

  # Game Settings
  gameAppId = "1169370"; # Steam App ID

  serverUpdateScript = pkgs.writeScriptBin "necesse-update" ''
    set -xeu

    ${pkgs.steamcmd}/bin/steamcmd \
      +force_install_dir $STATE_DIRECTORY \
      +login anonymous \
      +app_update ${gameAppId} validate \
      +quit
  '';
in
{
  options.services.necesse-server = mkOption {
    type = types.submodule (import ./backend-options.nix);
  };

  config = mkIf cfg.enable {
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.port cfg.queryPort];
      allowedUDPPorts = [cfg.port cfg.queryPort];
    };

    nixpkgs.config.allowUnfreePredicate = lib.mkDefault (pkg: builtins.elem (lib.getName pkg) [
      "steam"
      "steamcmd"
      "steam-original"
      "steam-unwrapped"
      "steam-run"
      "motortown-server"
      "steamworks-sdk-redist"
    ]);

    programs.steam = {
      enable = lib.mkDefault true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      protontricks.enable = lib.mkDefault true;
    };

    users.groups.modders = {
      members = [ cfg.user ];
    };

    systemd.services.necesse-server = {
      wantedBy = [ "multi-user.target" ]; 
      after = [ "network.target" ];
      description = "Necesse Dedicated Server";
      environment = cfg.environment;
      restartIfChanged = false;
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "modders";
        Restart = "always";
        EnvironmentFile = cfg.credentialsFile;
        KillSignal = "SIGKILL";
        StateDirectory = cfg.stateDirectory;
        StateDirectoryMode = "770";
        ExecStart="/bin/sh -c \"$STATE_DIRECTORY/Necesse\ Dedicated\ Server/StartServer-nogui.sh -localdir -world AMC1\"";
      };
    };

    users.users.${cfg.user} = lib.mkDefault {
      isNormalUser = true;
      packages = [
        pkgs.steamcmd
        mods.installModsScriptBin
      ];
    };
  };
}
