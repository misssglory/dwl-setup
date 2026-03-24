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
        
        # Use wlroots 0.18 specifically
        wlroots_0_18 = pkgs.wlroots_0_18 or (pkgs.wlroots.override {
          # Ensure we're using version 0.18
          version = "0.18.0";
        });
        
        # The main dwl package with specific wlroots version
        dwl = pkgs.callPackage ./dwl.nix {
          inherit (self) src;
          wlroots = wlroots_0_18;
          enableXWayland = true;
        };
        
      in {
        packages = {
          inherit dwl;
          default = dwl;
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gawk
            wlr-randr
            xrandr
            pkg-config
            wayland
            wayland-protocols
            wlroots_0_18
          ];
        };
      }
    );
}
