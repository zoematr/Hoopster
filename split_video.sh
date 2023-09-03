#!/bin/bash

converted_video="testvideo.mp4"
counter=1

mkdir -p Hits
mkdir -p Misses

while read -r start end label; do
    case "$label" in
        H) output_folder="Hits" ;;
        M) output_folder="Misses" ;;
        *) echo "Unknown label $label"; continue ;;
    esac

    # Find a unique file name
    output_file="$output_folder/output_${counter}.mp4"
    while [[ -e "$output_file" ]]; do
        counter=$((counter+1))
        output_file="$output_folder/output_${counter}.mp4"
    done

    ffmpeg -ss "$start" -i "$converted_video" -to "$end" -c copy "$output_file"
    counter=$((counter+1))
done < times.txt
