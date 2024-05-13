#!/bin/bash
# The above line specifies the shell to use for executing this script.

# Define input and output file paths
input0="output/output_bottleneck/meta_data/meta_Stats.tab"
input1="output/output_bottleneck/meta_data/meta_images.tab"
input2="output/output_bottleneck/meta_data/metadata_h.tab"
output0="output/output_bottleneck/meta_file.tab"
sorted_Stats="output/output_bottleneck/meta_data/meta_Stats_sorted.tab"
sorted_image="output/output_bottleneck/meta_data/meta_images_sorted.tab"
sorted_metadata_h="output/output_bottleneck/meta_data/metadata_h_sorted.tab"
storing_file="output/output_bottleneck/meta_data/temp_meta_file.tab"

# Sort input files and store sorted versions in separate files
(head -n 1 $input1 && tail -n +2 $input1 | sort -t$'\t' -k1,1) > $sorted_image
(head -n 1 $input0 && tail -n +2 $input0 | sort -t$'\t' -k2,2) > $sorted_Stats
(head -n 1 $input2 && tail -n +2 $input2 | sort -t$'\t' -k2,2) > $sorted_metadata_h

# Combine sorted files into a temporary file
join -t$'\t' -1 2 -2 1 $sorted_Stats $sorted_image > $storing_file
join -t$'\t' -1 1 -2 2 $storing_file $sorted_metadata_h > $output0

# Remove temporary file
rm $storing_file
