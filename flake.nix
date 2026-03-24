{
  description = "Custom dwl build with dynamic resolution adjustment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      # Define the source as an output
      src = self;
      
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Use wlroots 0.18 specifically
        wlroots_0_18 = pkgs.wlroots_0_18 or (pkgs.wlroots.overrideAttrs (old: {
          version = "0.18.0";
          src = pkgs.fetchFromGitHub {
            owner = "swaywm";
            repo = "wlroots";
            rev = "0.18.0";
            sha256 = "sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=";
          };
        }));
        
        # The main dwl package
        dwl = pkgs.callPackage ./dwl.nix {
          inherit src;
          wlroots = wlroots_0_18;
          enableXWayland = true;
          gawk = pkgs.gawk;
          wlr-randr = pkgs.wlr-randr;
          xrandr = pkgs.xrandr;
        };
        
      in {
        packages = {
          dwl = dwl;
          default = dwl;
        };
        
        # Expose the source for use in other flakes
        inherit src;
        
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
