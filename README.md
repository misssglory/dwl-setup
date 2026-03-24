# dwl-setup - Custom dwl with dynamic configuration

This flake provides a custom build of dwl with dynamic configuration adjustment based on screen resolution.

## Features

- Dynamic resolution detection using wlr-randr/xrandr
- Automatic scaling factor calculation based on diagonal pixels
- Mouse speed adjustment using square root of pixel ratio
- Acceleration speed optimization
- Nix flake integration for easy use in NixOS

## Usage

### As a flake input

Add to your `flake.nix`:

```nix
{
  inputs.dwl.url = "github:misssglory/dwl-setup";
  
  outputs = { self, nixpkgs, dwl, ... }: {
    nixosConfigurations.your-machine = nixpkgs.lib.nixosSystem {
      modules = [
        {
          environment.systemPackages = [ dwl.packages.${system}.default ];
        }
      ];
    };
  };
}
