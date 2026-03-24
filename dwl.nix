{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, wayland
, wayland-protocols
, wlroots  # This will be passed from the flake
, libxcb
, libX11
, xwayland
, src
, enableXWayland ? true
, gawk
, wlr-randr
, xrandr
}:

stdenv.mkDerivation {
  pname = "dwl";
  version = "0.7";
  
  inherit src;
  
  nativeBuildInputs = [ pkg-config gawk ];
  
  buildInputs = [
    wayland
    wayland-protocols
    wlroots  # Use the specific version passed from flake
  ] ++ lib.optionals enableXWayland [
    libX11
    libxcb
    xwayland
  ];
  
  postPatch = ''
    echo "=== dwl build: Dynamic resolution adjustment ==="
    echo "Using wlroots version: ${wlroots.version or "unknown"}"
    
    # Check if adjustment script exists
    if [ -f adjust-dwl-config.sh ]; then
      echo "Found adjustment script, making executable..."
      chmod +x adjust-dwl-config.sh
      
      # Make sure we have the required tools in PATH during build
      export PATH="${gawk}/bin:${wlr-randr}/bin:${xrandr}/bin:$PATH"
      
      echo "Running configuration adjustment..."
      ./adjust-dwl-config.sh config.h
      
      if [ $? -eq 0 ]; then
        echo "✅ Configuration successfully adjusted"
      else
        echo "⚠️  Adjustment script failed, using original config.h"
      fi
    else
      echo "⚠️  No adjustment script found, using original config.h"
    fi
    
    echo ""
    echo "Final configuration values:"
    echo "--- Monitor configuration ---"
    grep -A 2 "eDP-1" config.h | head -3 || echo "No eDP-1 found"
    echo "--- Acceleration speed ---"
    grep "accel_speed" config.h || echo "No accel_speed found"
    echo "--- End configuration ---"
  '';
  
  buildPhase = ''
    runHook preBuild
    make XWAYLAND=${if enableXWayland then "-DXWAYLAND" else ""}
    runHook postBuild
  '';
  
  installPhase = ''
    runHook preInstall
    make PREFIX=$out install
    runHook postInstall
  '';
  
  meta = with lib; {
    description = "A dynamic Wayland compositor based on wlroots with dynamic resolution-based configuration";
    homepage = "https://github.com/misssglory/dwl-setup";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
