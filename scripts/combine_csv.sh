#!/bin/bash

input_dir="processed_data"
output_dir="combined_output"
output_file="$output_dir/combined_pvalues.csv"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Add header from the first CSV file
head -n 1 $(find "$input_dir" -type f -name '*.csv' | head -n 1) > "$output_file"

# Add all data excluding headers
find "$input_dir" -type f -name 'PMC*.csv' -exec tail -n +2 {} + >> "$output_file"

# Move the output file back to the original directory if needed
# mv "$output_file" "$input_dir/combined_pvalues.csv"

# Clean up the individual CSV files by removing the entire directory
rm -rf "$input_dir"

echo "Combined CSV file created at $output_file"
echo "All individual CSV files removed."
