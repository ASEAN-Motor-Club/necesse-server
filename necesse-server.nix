{ lib, pkgs, config, ...}:
with lib;
let
  cfg = config.services.necesse-server;
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
  imports = [
    ./logger.nix
  ];
  options.services.necesse-server = mkOption {
    type = types.submodule (import ./backend-options.nix);
  };

  config = mkIf cfg.enable {
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.port];
      allowedUDPPorts = [cfg.port];
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
      members = [ cfg.user "amc" ];
      gid = 987;
    };

    systemd.sockets.necesse-server = {
      description = "Command Input FIFO for Necesse Server";
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenFIFO = "/run/necesse-server/server.fifo";
        SocketUser = cfg.user;
        SocketGroup = "modders";
        SocketMode = "0660";     # Read/Write for User & Group
        DirectoryMode = "0770";  # Ensure parent directory is accessible by group
        RemoveOnStop = "true";
      };
    };

    systemd.services.necesse-server = {
      wantedBy = [ "multi-user.target" ]; 
      after = [ "network.target" "necesse-server.socket" ];
      requires = [ "necesse-server.socket" ];
      description = "Necesse Dedicated Server";
      environment = cfg.environment;
      restartIfChanged = false;
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "modders";
        Restart = "always";
        # EnvironmentFile = lib.mkIf (cfg.credentialsFile != null) cfg.credentialsFile;
        KillSignal = "SIGKILL";
        StateDirectory = cfg.stateDirectory;
        StateDirectoryMode = "770";
        StandardInput="socket";
        StandardOutput="journal";
      };
      script=''
        # ${lib.getExe serverUpdateScript}
        exec ${pkgs.steam-run}/bin/steam-run $STATE_DIRECTORY/StartServer-nogui.sh -localdir -world AMC1 -owner freeman
      '';
    };

    users.users.${cfg.user} = lib.mkDefault {
      isNormalUser = true;
      packages = [
        pkgs.steamcmd
        mods.installModsScriptBin
      ];
    };

    services.necesse-server-logger = {
      enable = cfg.enableLogStreaming;
      serverLogsPath = "/var/lib/${cfg.stateDirectory}/logs";
      tag = "necesse";
    };
  };
}
