#!/bin/bash

output_file="processed_data/combined_pvalues.csv"
input_dir="processed_data"

# Remove the output file if it exists
rm -f "$output_file"

# Add the header from the first CSV file
first_file=$(find "$input_dir" -type f -name '*.csv' | head -n 1)
head -n 1 "$first_file" > "$output_file"

# Loop through all CSV files and append their content to the output file (excluding headers)
for csv_file in "$input_dir"/*.csv; do
  if [ "$csv_file" != "$first_file" ]; then
    tail -n +2 "$csv_file" >> "$output_file"
  fi
  # Remove the processed CSV file
  rm -f "$csv_file"
done

# Process the first file last to ensure all files are included
tail -n +2 "$first_file" >> "$output_file"
rm -f "$first_file"

echo "Combined CSV file created at $output_file"
