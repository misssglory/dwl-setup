set -e

CONFIG_H="${1:-config.h}"
LOG_FILE="/tmp/dwl-config-adjust.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to detect resolution
detect_resolution() {
    local res=""
    
    # Try wlr-randr (Wayland)
    if command -v wlr-randr &> /dev/null; then
        res=$(wlr-randr 2>/dev/null | grep -A 1 "eDP-1" | grep "current" | awk '{print $1}')
    fi
    
    # Try xrandr (X11)
    if [ -z "$res" ] && command -v xrandr &> /dev/null; then
        res=$(xrandr 2>/dev/null | grep " connected" | grep -oP '\d+x\d+' | head -n1)
    fi
    
    # Try reading from sysfs
    if [ -z "$res" ] && [ -f "/sys/class/drm/card0-eDP-1/modes" ]; then
        res=$(head -n1 /sys/class/drm/card0-eDP-1/modes 2>/dev/null | grep -oP '\d+x\d+')
    fi
    
    # Default fallback
    if [ -z "$res" ]; then
        res="1920x1080"
        log_message "WARNING: Could not detect resolution, using default: $res"
    fi
    
    echo "$res"
}

# Function to calculate values using awk
calculate_values() {
    local width=$1
    local height=$2
    
    awk -v w="$width" -v h="$height" '
    BEGIN {
        # Calculate diagonal in pixels
        diagonal = sqrt(w * w + h * h)
        reference_diagonal = 2203  # 1920x1080 diagonal
        
        # Calculate scale (diagonal ratio)
        scale = diagonal / reference_diagonal
        if (scale < 0.5) scale = 0.5
        if (scale > 2.5) scale = 2.5
        
        # Calculate total pixels
        total_pixels = w * h
        reference_pixels = 1920 * 1080
        
        # Mouse speed (inverse square root of pixel ratio)
        mouse_speed = sqrt(reference_pixels / total_pixels) * 1.2
        if (mouse_speed < 0.5) mouse_speed = 0.5
        if (mouse_speed > 2.0) mouse_speed = 2.0
        
        # Acceleration speed (proportional to diagonal)
        accel_speed = (diagonal / reference_diagonal) * 0.8
        if (accel_speed < 0.5) accel_speed = 0.5
        if (accel_speed > 1.5) accel_speed = 1.5
        
        # Format to one decimal place
        printf("%.1f %.1f %.1f", scale, mouse_speed, accel_speed)
    }'
}

# Main script
main() {
    log_message "=== Starting dwl configuration adjustment ==="
    
    # Check if config.h exists
    if [ ! -f "$CONFIG_H" ]; then
        log_message "ERROR: config.h not found at $CONFIG_H"
        exit 1
    fi
    
    # Detect resolution
    RESOLUTION=$(detect_resolution)
    log_message "Detected resolution: $RESOLUTION"
    
    # Parse resolution
    WIDTH=$(echo "$RESOLUTION" | cut -d'x' -f1)
    HEIGHT=$(echo "$RESOLUTION" | cut -d'x' -f2)
    
    # Calculate values
    VALUES=$(calculate_values "$WIDTH" "$HEIGHT")
    SCALE=$(echo "$VALUES" | awk '{print $1}')
    MOUSE_SPEED=$(echo "$VALUES" | awk '{print $2}')
    ACCEL_SPEED=$(echo "$VALUES" | awk '{print $3}')
    
    # Log calculations
    log_message ""
    log_message "=== Resolution Analysis ==="
    log_message "Width: $WIDTH pixels"
    log_message "Height: $HEIGHT pixels"
    log_message "Total pixels: $((WIDTH * HEIGHT))"
    
    DIAGONAL=$(awk -v w="$WIDTH" -v h="$HEIGHT" 'BEGIN {printf "%.0f", sqrt(w*w + h*h)}')
    log_message "Diagonal pixels: $DIAGONAL"
    log_message ""
    log_message "=== Calculated Values ==="
    log_message "Scale factor: ${SCALE}f (from diagonal ratio)"
    log_message "Mouse speed: ${MOUSE_SPEED}f (inverse square root of pixel count)"
    log_message "Acceleration speed: $ACCEL_SPEED (proportional to diagonal)"
    log_message ""
    
    # Backup original config
    BACKUP_FILE="${CONFIG_H}.backup.$(date +%s)"
    cp "$CONFIG_H" "$BACKUP_FILE"
    log_message "Backup created: $BACKUP_FILE"
    
    # Update monitor configuration
    if grep -q "eDP-1" "$CONFIG_H"; then
        sed -i "s/\({\s*\"eDP-1\"\s*,\s*\)[0-9.]\+f\(,\s*[0-9]\+,\s*\)[0-9.]\+f\(,\s*&layouts\[0\],.*\)/\1${SCALE}f\2${MOUSE_SPEED}f\3/" "$CONFIG_H"
        log_message "✓ eDP-1 line updated"
    fi
    
    # Update accel_speed
    if grep -q "accel_speed" "$CONFIG_H"; then
        sed -i "s/static const double accel_speed = [0-9.]\+;/static const double accel_speed = ${ACCEL_SPEED};/" "$CONFIG_H"
        log_message "✓ accel_speed updated"
    fi
    
    # Verify changes
    log_message ""
    log_message "=== Verification ==="
    log_message "Updated eDP-1 line:"
    grep -n "eDP-1" "$CONFIG_H" | head -1
    log_message "Updated accel_speed line:"
    grep -n "accel_speed" "$CONFIG_H" | head -1
    
    log_message ""
    log_message "=== Configuration Complete ==="
    log_message "Scale: ${SCALE}f"
    log_message "Mouse speed: ${MOUSE_SPEED}f"
    log_message "Acceleration: $ACCEL_SPEED"
    
    exit 0
}

# Run main function
main "$@"
