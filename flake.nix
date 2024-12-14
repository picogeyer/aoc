{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }:
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;

  in
  {
    formatter = pkgs.x86_64-linux.nixfmt-rfc-style;
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        zig
        nil
      ];
    };
  };
}
