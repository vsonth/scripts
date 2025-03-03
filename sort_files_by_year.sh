#!/bin/bash

# Check if a directory is provided
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/directory [days]"
    echo "Example: $0 /path/to/directory 30 (only move files older than 30 days)"
    exit 1
fi

TARGET_DIR="$1"
DAYS_OLD=${2:-0}  # Default to 0 (no filtering)

SORTED_DIR="$TARGET_DIR/Sorted"
SIZE_REPORT="$SORTED_DIR/file_sizes.txt"
LOG_FILE="$SORTED_DIR/sort_log.txt"

# Ensure Sorted directory exists
mkdir -p "$SORTED_DIR"

# Start logging
echo "===== Sorting Started: $(date) =====" >> "$LOG_FILE"

# Function to determine the year of a file
get_year() {
    last_modified_year=$(stat -f "%Sm" -t "%Y" "$1")
    echo "$last_modified_year"
}

# Function to check if a file is too deep (more than 5 levels)
is_too_deep() {
    local file="$1"
    local depth=$(echo "$file" | tr '/' '\n' | wc -l)
    
    if [[ "$depth" -gt 5 ]]; then
      echo "Too Deep "$file""
        return 0  # Too deep
    else
        return 1  # Acceptable
    fi
}

# Function to move a file to the correct category and year
move_file() {
    local file="$1"
    
    # Skip files already inside the sorted directory
    if [[ "$file" == "$SORTED_DIR"* ]]; then
        return
    fi

    # Skip files that are too deep
    if is_too_deep "$file"; then
        echo "Skipping (too deep): $file" >> "$LOG_FILE"
        return
    fi

    # Check file extension
    ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    # Determine file category
    case "$ext" in
        jpg|jpeg|png|gif|bmp|tiff|svg) category="Images" ;;
        mp4|mov|avi|mkv|flv|wmv) category="Videos" ;;
        mp3|wav|aac|flac|ogg) category="Audio" ;;
        pdf|doc|docx|txt|md|ppt|pptx|xls|xlsx) category="Documents" ;;
        zip|rar|tar|gz|7z) category="Archives" ;;
        dmg|pkg|app|exe|sh) category="Executables" ;;
        py|js|java|cpp|c|html|css|php|go|rb) category="Code" ;;
        stl) category="3D_Models" ;;  # Specific sorting for STL files
        *) category="Others" ;;
    esac

    # Get last modified year
    year=$(get_year "$file")

    # Ensure category and year folder exist
    mkdir -p "$SORTED_DIR/$category/$year"

    # Move the file
    mv "$file" "$SORTED_DIR/$category/$year/"
    echo "Moved: $file -> $SORTED_DIR/$category/$year/" >> "$LOG_FILE"
}

# Step 1: Process all files in the target directory (excluding already sorted files)
find "$TARGET_DIR" -type f | while read -r file; do
    # Check file age if filtering is enabled
    if [[ "$DAYS_OLD" -gt 0 ]]; then
        last_modified_days=$(( ($(date +%s) - $(stat -f "%m" "$file")) / 86400 ))

        if [[ "$last_modified_days" -lt "$DAYS_OLD" ]]; then
            echo "Skipping: $file (Modified $last_modified_days days ago)" >> "$LOG_FILE"
            continue
        fi
    fi

    move_file "$file"
done

# Step 2: Check inside the Sorted directory for misplaced STL files
find "$SORTED_DIR" -type f -name "*.stl" | while read -r file; do
    correct_path="$SORTED_DIR/3D_Models/$(get_year "$file")/"
    
    # Move if it's in the wrong folder
    if [[ "$file" != "$correct_path"* ]]; then
        mkdir -p "$correct_path"
        mv "$file" "$correct_path"
        echo "Reorganized STL: $file -> $correct_path" >> "$LOG_FILE"
    fi
done

# Delete empty folders
find "$SORTED_DIR" -type d -empty -delete

# Update file size breakdown
find "$SORTED_DIR" -type f -exec du -h {} + | sort -hr > "$SIZE_REPORT"

echo "Sorting complete. Updated file size breakdown in '$SIZE_REPORT'." | tee -a "$LOG_FILE"
echo "===== Sorting Finished: $(date) =====" >> "$LOG_FILE"