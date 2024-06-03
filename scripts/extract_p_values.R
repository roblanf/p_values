library(tidyverse)
library(xml2)
library(stringr)

# Define input and output paths
input_file_path <- "test_set"
output_file_path <- "processed_data/pvalues_extracted.csv"

dir.create("processed_data", showWarnings = FALSE)


# Function to clean up titles extracted from XML tags
clarify_title <- function(tag) {
  title <- xml_text(tag)
  title <- str_replace_all(title, "[\r\n]", " ")
  return(title)
}

# Function to check if a candidate string is a p-value
is_pvalue <- function(candidate) {
  return(str_detect(candidate, "^0?\\.\\d+|<|>|="))
}

# Function to extract p-values from text
get_pvalues <- function(text) {
  p_values <- str_extract_all(text, "\\b(p|P)\\s*([<>]=?|=)\\s*0?\\.\\d+\\b")[[1]]
  p_values <- str_replace_all(p_values, "\\s+", "")
  return(p_values)
}


extract_section_pvalues <- function(doc, pmcid, section) {
  section_text <- xml_text(xml_find_all(doc, paste0("//", section)))
  sentences <- unlist(strsplit(section_text, "(?<=[.!?])\\s*(?=[A-Z])", perl = TRUE))
  results <- tibble()
  
  for (sentence in sentences) {
    p_values <- get_pvalues(sentence)
    for (p_val in p_values) {
      temp_results <- tibble(
        p_value = str_extract(p_val, "0?\\.\\d+"),
        operator = str_extract(p_val, "[<>]=?|="),
        context = sentence,
        pmcid = pmcid,
        section = section
      )
      results <- bind_rows(results, temp_results)
    }
  }
  
  return(results)
}

# Function to process an individual XML paper
process_paper <- function(paper_path) {
  doc <- read_xml(paper_path)
  pmcid <- xml_text(xml_find_first(doc, "//article-id[@pub-id-type='pmc']"))
  
  abstract_pvalues <- extract_section_pvalues(doc, pmcid, "abstract")
  body_pvalues <- extract_section_pvalues(doc, pmcid, "body")
  
  return(bind_rows(abstract_pvalues, body_pvalues))
}

# Function to get all paper paths from the directory
get_all_papers <- function(head_directory_path) {
  return(list.files(head_directory_path, pattern = "\\.xml$", full.names = TRUE, recursive = TRUE))
}



# Get the list of all XML files to be processed
paper_paths <- get_all_papers(input_file_path)

# Initialize an empty tibble for results
all_results <- tibble(
  p_value = character(),
  operator = character(),
  context = character(),
  pmcid = character(),
  section = character()
)

# Process each paper and append results to all_results
for (i in seq_along(paper_paths)) {
  
  paper_path = paper_paths[i]
  
  doc <- read_xml(paper_path)
  pmcid <- xml_text(xml_find_first(doc, "//article-id[@pub-id-type='pmc']"))
  
  cat(pmcid, ": ")
  
  paper_results <- process_paper(paper_path)

  n = nrow(paper_results)
  
  cat("got ", n, " p values\n")
  
  all_results <- bind_rows(all_results, paper_results)
  
  # Print progress every 10 papers
  if (i %% 10 == 0) {
    cat("Processed", i, "papers\n")
  }
}

# Write the results to a CSV file
write_csv(all_results, output_file_path)

print("P-values extraction completed and saved to raw_data/pvalues_extracted.csv")
