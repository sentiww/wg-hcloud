{
  description = "Hetzner WireGuard NixOS VPS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    sops-nix.url = "github:Mic92/sops-nix";
    disko.url = "github:nix-community/disko";
  };

  outputs = { self, nixpkgs, sops-nix, disko, ... }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
  in
  {
    nixosConfigurations.wg-vps = lib.nixosSystem {
      inherit system;
      modules = [
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
        ./nixos/disko.nix
        ./nixos/wg-vps.nix
      ];
    };
  };
}
