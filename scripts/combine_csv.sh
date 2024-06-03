#!/bin/bash

output_file="processed_data/combined_pvalues.csv"
input_dir="processed_data"

# Remove the output file if it exists
rm -f "$output_file"

# Find all CSV files in the directory
csv_files=$(find "$input_dir" -type f -name '*.csv')

# Check if there are any CSV files to process
if [ -z "$csv_files" ]; then
  echo "No CSV files found in $input_dir"
  exit 1
fi

# Add the header from the first CSV file
first_file=$(echo "$csv_files" | head -n 1)
head -n 1 "$first_file" > "$output_file"

# Loop through all CSV files and append their content to the output file (excluding headers)
for csv_file in $csv_files; do

  echo $csv_file

  # Skip the header for all but the first file
  tail -n +2 "$csv_file" >> "$output_file"
  # Remove the processed CSV file
  rm -f "$csv_file"

done

echo "Combined CSV file created at $output_file"
