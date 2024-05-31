#!/bin/bash

# Create directories
mkdir -p raw_data/xml_documents
mkdir -p raw_data/csv_files

# Unzip all .tar.gz files into /raw_data/xml_documents
for tar_file in downloads/*.tar.gz; do
    tar -xzf "$tar_file" -C raw_data/xml_documents
done

# Combine all .csv files into one
combined_csv="raw_data/combined_filelists.csv"
head -n 1 $(ls downloads/*.csv | head -n 1) > "$combined_csv" # add header

for csv_file in downloads/*.csv; do
    tail -n +2 "$csv_file" >> "$combined_csv"
done

echo "All XML files are extracted into raw_data/xml_documents"
echo "Combined CSV file is created at raw_data/combined_filelists.csv"
