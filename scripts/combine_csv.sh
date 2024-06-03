#!/bin/bash

input_dir="processed_data"
output_file="processed_data/combined_pvalues.csv"

# Add header from the first CSV file
head -n 1 $(find "$input_dir" -type f -name '*.csv' | head -n 1) > "$output_file"

# Add all data excluding headers
find "$input_dir" -type f -name '*.csv' -exec tail -n +2 {} + >> "$output_file"

# Clean up individual CSV files
find "$input_dir" -type f -name 'PMC*.csv' -exec rm {} \;
