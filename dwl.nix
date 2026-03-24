{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, wayland
, wayland-scanner
, wayland-protocols
, wlroots
, libxcb
, libX11
, xwayland
, xorg
, xcbutilwm
, libxkbcommon
, pixman
, libpng
, libGL
, mesa
, udev
, libinput
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
  
  nativeBuildInputs = [
    pkg-config
    wayland-scanner
    gawk
  ];
  
  buildInputs = [
    wayland
    wayland-protocols
    wlroots
    libxkbcommon
    libxcb
    xorg.libxcb
    xcbutilwm
    pixman
    libpng
    libGL
    mesa
    udev
    libinput
  ] ++ lib.optionals enableXWayland [
    libX11
    xwayland
  ];
  
  # Set up build environment
  preBuild = ''
    # Ensure wayland-scanner is in PATH
    export PATH="${wayland-scanner}/bin:$PATH"
    
    # Set PKG_CONFIG_PATH to find all required packages
    export PKG_CONFIG_PATH="${wlroots}/lib/pkgconfig:${libxkbcommon}/lib/pkgconfig:${xcbutilwm}/lib/pkgconfig:${libxcb}/lib/pkgconfig:${pixman}/lib/pkgconfig:${libpng}/lib/pkgconfig:${libGL}/lib/pkgconfig:${mesa}/lib/pkgconfig:${udev}/lib/pkgconfig:${libinput}/lib/pkgconfig:$PKG_CONFIG_PATH"
    
    echo "PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
    echo "Checking critical dependencies:"
    for dep in wlroots xkbcommon xcb-icccm pixman-1 libpng gl mesa; do
      if pkg-config --exists $dep 2>/dev/null; then
        echo "✓ $dep found ($(pkg-config --modversion $dep))"
      else
        echo "✗ $dep missing"
      fi
    done
    
    # Set include paths for compilation
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${pixman}/include/pixman-1"
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${wlroots}/include/wlroots-0.18"
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${libxkbcommon}/include"
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${libxcb}/include"
  '';
  
  postPatch = ''
    echo "=== dwl build: Dynamic resolution adjustment ==="
    echo "Using wlroots version: ${wlroots.version or "unknown"}"
    
    # Check if adjustment script exists
    if [ -f adjust-dwl-config.sh ]; then
      echo "Found adjustment script, making executable..."
      chmod +x adjust-dwl-config.sh
      
      # Make tools available in PATH
      export PATH="${gawk}/bin:${wlr-randr}/bin:${xrandr}/bin:$PATH"
      
      echo "Running configuration adjustment..."
      
      # Run the script with timeout to avoid hanging
      if timeout 30 ./adjust-dwl-config.sh config.h 2>&1; then
        echo "✅ Configuration successfully adjusted"
      else
        echo "⚠️  Adjustment script failed or timed out"
        echo "Using original config.h without modifications"
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
    maintainers = with maintainers; [ misssglory ];
  };
}
