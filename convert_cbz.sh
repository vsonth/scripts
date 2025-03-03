#!/bin/bash

# Ensure required tools are installed
for cmd in unzip magick gs parallel; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed. Install it first."
        exit 1
    fi
done

# Fix $PWD issue by switching to a safe working directory
cd "$(pwd -P)" || exit

# Function to sanitize directory name if necessary
sanitize_directory() {
    safe_dir=$(echo "$PWD" | tr -cd '[:alnum:]_/')
    if [[ "$PWD" != "$safe_dir" ]]; then
        echo "Renaming directory to remove unsupported characters..."
        parent_dir=$(dirname "$PWD")
        new_name="$parent_dir/$(basename "$safe_dir")"
        mv "$PWD" "$new_name"
        cd "$new_name" || exit
        echo "Directory renamed to: $new_name"
    fi
}

# Function to process a single CBZ file and convert it to a compressed PDF
process_cbz() {
    cbz_file="$1"
    [[ ! -f "$cbz_file" ]] && return  # Skip if file doesn't exist

    echo "Processing: $cbz_file"

    base_name="${cbz_file%.cbz}"  # Remove .cbz extension
    temp_dir="${base_name}_extracted"

    mkdir -p "$temp_dir"
    unzip -q "$cbz_file" -d "$temp_dir"

    cd "$temp_dir" || exit

    # Find all images (JPG, PNG, WebP) and sort them
    image_files=$(ls *.{webp,jpg,jpeg,png} 2> /dev/null | sort)
    if [ -z "$image_files" ]; then
        echo "Warning: No image files found in $cbz_file. Skipping..."
        cd ..
        rm -rf "$temp_dir"
        return
    fi

    compressed_pdf="../${base_name}_compressed.pdf"

    # Convert images to a single compressed PDF in one step
    magick $image_files -quality 75 -density 150 -compress jpeg pdf:- | \
        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$compressed_pdf" -

    # Check if PDF creation was successful
    if [[ ! -f "$compressed_pdf" ]]; then
        echo "Error: PDF conversion failed for $cbz_file. Retaining original file."
        cd ..
        rm -rf "$temp_dir"
        return
    fi

    echo "Compressed PDF created: $compressed_pdf"

    # Clean up: remove extracted images
    cd ..
    rm -rf "$temp_dir"
}

# Function to pad CBZ filenames with leading zeros (this will be done at the end)
pad_filenames() {
    for file in *.cbz; do
        [[ ! -f "$file" ]] && continue  # Skip if no CBZ files found
        base_name=$(echo "$file" | grep -o '[0-9]\+' | awk '{printf "%03d", $1}')
        new_name="Chapter ${base_name}.cbz"
        if [[ "$file" != "$new_name" ]]; then
            mv "$file" "$new_name"
            echo "Renamed: $file → $new_name"
        fi
    done
}

# Get the number of CPU cores (works on most systems)
cpu_cores=$(sysctl -n hw.ncpu)  # This works on macOS
if [[ -z "$cpu_cores" ]]; then
    cpu_cores=2  # Default to 2 cores if unable to detect
fi

# Run the functions
sanitize_directory

# Find all CBZ files and process them in parallel (skip renaming for now)
export -f process_cbz
find . -name "*.cbz" | parallel --will-cite -j "$cpu_cores" process_cbz {}

# Now pad the filenames with leading zeros
# pad_filenames

echo "All files processed!"
