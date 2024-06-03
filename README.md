# p_values
Get p-values from PMC articles

1. Download all the PMC OA articles 

```bash
bash download_pmc.sh
```

2. Extract all the pmc articles 

Articles go to `raw_data/xml_documents` 

Info on each paper goes to: `raw_data/combined_filelists.csv`

```bash
bash process_pmc.sh
```

3. 
