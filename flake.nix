{
  description = "Hetzner WireGuard NixOS VPS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, sops-nix, ... }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
  in
  {
    nixosConfigurations.wg-vps = lib.nixosSystem {
      inherit system;
      modules = [
        sops-nix.nixosModules.sops
        ./nixos/wg-vps.nix
      ];
    };
  };
}
