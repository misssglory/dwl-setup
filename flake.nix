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
        wlroots_0_18 = pkgs.wlroots_0_18 or (pkgs.wlroots.overrideAttrs (old: {
          version = "0.18.0";
          src = pkgs.fetchFromGitHub {
            owner = "swaywm";
            repo = "wlroots";
            rev = "0.18.0";
            sha256 = "sha256-0d67j1qylz0vqzpw0djzb6sny8mc3yg0q2j5q4wfay48y4xw0gmy";
          };
        }));
        
        # Fetch the source from your repository
        src = pkgs.fetchFromGitHub {
          owner = "misssglory";
          repo = "dwl-setup";
          rev = "2f44472cde81eb22cddb550f42059985bf7232c2";
          sha256 = "sha256-rNFNdI6DEOY1wDKOkqOjB3Kb26dKZ4iOwioYerA2Akc=";
        };
        
        # The main dwl package with all dependencies
        dwl = pkgs.callPackage ./dwl.nix {
          inherit src;
          wlroots = wlroots_0_18;
          wayland = pkgs.wayland;
          wayland-scanner = pkgs.wayland-scanner;
          wayland-protocols = pkgs.wayland-protocols;
          libxkbcommon = pkgs.libxkbcommon;
          libxcb = pkgs.libxcb;
          xcbutilwm = pkgs.xcbutilwm;
          pixman = pkgs.pixman;
          libpng = pkgs.libpng;
          libGL = pkgs.libGL;
          mesa = pkgs.mesa;
          udev = pkgs.udev;
          libinput = pkgs.libinput;
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
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gawk
            wlr-randr
            xrandr
            pkg-config
            wayland
            wayland-scanner
            wayland-protocols
            wlroots_0_18
            libxkbcommon
            libxcb
            xcbutilwm
            pixman
            libpng
            libGL
            mesa
            udev
            libinput
          ];
          
          shellHook = ''
            echo "=== dwl development environment ==="
            echo ""
            echo "Dependencies status:"
            echo "-------------------"
            
            # Check critical dependencies
            for dep in wlroots xkbcommon xcb-icccm pixman-1 libpng gl libinput; do
              if pkg-config --exists $dep 2>/dev/null; then
                echo "✓ $dep: $(pkg-config --modversion $dep)"
              else
                echo "✗ $dep: not found"
              fi
            done
            
            echo ""
            echo "To build dwl: nix build ."
            echo "To enter build environment: nix develop"
            echo "-------------------"
          '';
        };
      }
    );
}
