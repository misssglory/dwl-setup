{
  description = "Custom dwl build with dynamic resolution adjustment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # The main dwl package
        dwl = pkgs.callPackage ./dwl.nix {
          inherit (self) src;
          # Pass any build-time options
          enableXWayland = true;
        };
        
      in {
        # The main package output
        packages = {
          inherit dwl;
          default = dwl;
        };
        
        # For development shell (optional)
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gawk
            wlr-randr
            xrandr
            pkg-config
            wayland
            wayland-protocols
            wlroots
          ];
        };
      }
    );
}
