{ config, pkgs, lib, ... }:

let
  wgIf = "wg0";
  wgPort = 51820;
  wgAddr = "10.6.0.1/24";

  peersByName = import ./peers.nix;

  pskSecrets =
    lib.unique (lib.filter (s: s != null)
      (lib.mapAttrsToList (_: p: p.presharedKeySecret or null) peersByName));

  pskSecretAttrs =
    builtins.listToAttrs (map (name: {
      inherit name;
      value = {
        owner = "root";
        mode = "0400";
      };
    }) pskSecrets);

  peersList =
    lib.mapAttrsToList (_name: peer:
      let
        base = {
          publicKey = peer.publicKey;
          allowedIPs = peer.allowedIPs;
          persistentKeepalive = peer.persistentKeepalive or null;
          endpoint = peer.endpoint or null;
        };

        withPsk =
          if (peer ? presharedKeySecret)
          then base // {
            presharedKeyFile = config.sops.secrets.${peer.presharedKeySecret}.path;
          }
          else base;

      in lib.filterAttrs (_: v: v != null) withPsk
    ) peersByName;

in
{
  time.timeZone = "UTC";

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "prohibit-password";
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIdcypYPw+bTPjdOGk6681S7Gm9MbrRUD6xf94tgy+u7 wojciech.warwas01@gmail.com"
  ];


  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 51820 ];
    allowedUDPPorts = [ wgPort ];
    extraInputRules = ''  
    iifname "wg0" tcp dport 22 accept
    '';
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [
    "ahci"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/disk-main-root";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/disk-main-ESP";
    fsType = "vfat";
  };

  networking.nat = {
    enable = true;
    externalInterface = "eth0";
    internalInterfaces = [ wgIf ];
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    sops
    age
  ];

  sops = {
    defaultSopsFile = ../secrets/wireguard.yaml;

    age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0700 root root -"
  ];

  sops.secrets =
    pskSecretAttrs // {
      "wg/server_private_key" = {
        owner = "root";
        mode = "0400";
      };
    };

  networking.wireguard.interfaces.${wgIf} = {
    ips = [ wgAddr ];
    listenPort = wgPort;

    privateKeyFile = config.sops.secrets."wg/server_private_key".path;

    peers = peersList;
  };

  system.stateVersion = "24.11";
}
