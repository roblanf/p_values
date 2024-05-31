# p_values
Get p-values from PMC articles

# 1. Download all the PMC OA articles 

```bash
mkdir downloads
cd downloads

# Base URL
base_url="https://ftp.ncbi.nlm.nih.gov/pub/pmc/oa_bulk/oa_noncomm/xml/"

# Get the list of all files from the directory
file_list=$(curl -s $base_url | grep -Eo 'oa_noncomm_xml\.[^"]+\.(tar\.gz|filelist\.csv)')

# Download each file
for file in $file_list; do
    wget -nc "${base_url}${file}"
done

cd ..
```
