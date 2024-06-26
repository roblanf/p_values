#!/bin/bash

# Create directories
mkdir -p raw_data/xml_documents
mkdir -p raw_data/csv_files

# Unzip all .tar.gz files directly into /raw_data/xml_documents
for tar_file in downloads/*.tar.gz; do
    tar -xzf "$tar_file" -C raw_data/xml_documents --strip-components=1
done

# Combine all .csv files into one
combined_csv="raw_data/combined_filelists.csv"
head -n 1 $(ls downloads/*.csv | head -n 1) > "$combined_csv" # add header

for csv_file in downloads/*.csv; do
    tail -n +2 "$csv_file" >> "$combined_csv"
done

# Don't need this anymore
rmdir raw_data/csv_files

# remove duplicate lines from the CSV
awk '!seen[$0]++' raw_data/combined_filelists.csv > raw_data/papers.csv

# clean up
rm raw_data/combined_filelists.csv

echo "All XML files are extracted into raw_data/xml_documents"
echo "Combined CSV file is created at raw_data/papers.csv"
