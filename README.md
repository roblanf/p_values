# p_values
Get p-values from PMC articles

1. Download all the PMC OA articles 

```bash
bash scripts/download_pmc.sh
```

2. Extract all the pmc articles 

Articles go to `raw_data/xml_documents` 

Info on each paper goes to: `raw_data/combined_filelists.csv`

```bash
bash scripts/process_pmc.sh
```

3. Get the p_values

```R
Rscript scripts/extract_p_values.R
```

This will create one csv file in `processed_data` for every paper with at least one detected p value.

4. Combine p values into one csv file

```bash
bash scripts/combine_csv.sh
```

5. Create a csv file without the 'context' column to save space

```bash
bash scripts/remove_context.sh
```

