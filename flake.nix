{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    {
      defaultPackage.x86_64-linux =
        (import nixpkgs { system = "x86_64-linux"; }).callPackage ./default.nix
          { };
      defaultPackage.aarch64-linux =
        (import nixpkgs { system = "aarch64-linux"; }).callPackage ./default.nix
          { };
    };
}
