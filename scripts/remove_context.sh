#!/bin/bash

# Define input and output file paths
input_file="processed_data/combined_pvalues.csv"
output_file="processed_data/combined_pvalues_no_context.csv"

# Remove the context column (third column) from the CSV file
cut -d',' -f1-2,4-6 "$input_file" > "$output_file"

echo "CSV file without the context column created at $output_file"
