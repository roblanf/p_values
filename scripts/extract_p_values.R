library(tidyverse)
library(xml2)
library(stringr)
library(parallel)
library(pbapply)

input_file_path <- "test_set"
output_dir <- "processed_data"
exclusion_file <- "exclusion_phrases.txt"

dir.create(output_dir, showWarnings = FALSE)

clarify_title <- function(tag) {
  title <- xml_text(tag)
  title <- str_replace_all(title, "[\r\n]", " ")
  return(title)
}

is_pvalue <- function(candidate) {
  return(str_detect(candidate, "^0?\\.\\d+|<|>|="))
}

get_pvalues <- function(text) {
  p_values <- str_extract_all(text, "\\b(p|P)\\s*([<>]=?|=)\\s*0?\\.\\d+\\b")[[1]]
  p_values <- str_replace_all(p_values, "\\s+", "")
  return(p_values)
}

load_exclusion_phrases <- function(file) {
  return(tolower(read_lines(file)))
}

exclusion_phrases <- load_exclusion_phrases(exclusion_file)

extract_section_pvalues <- function(doc, pmcid, section) {
  section_text <- xml_text(xml_find_all(doc, paste0("//", section)))
  sentences <- unlist(strsplit(section_text, "(?<=[.!?])\\s*(?=[A-Z])", perl = TRUE))
  results <- tibble()
  
  for (sentence in sentences) {
    # Exclude sentences with stars directly before the p value
    if (str_detect(sentence, "\\*\\s*[pP]\\s*[<>]=?\\s*0?\\.\\d+")) {
      next
    }
    
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

process_paper <- function(paper_path) {
  doc <- read_xml(paper_path)
  pmcid <- xml_text(xml_find_first(doc, "//article-id[@pub-id-type='pmc']"))
  
  abstract_pvalues <- extract_section_pvalues(doc, pmcid, "abstract")
  body_pvalues <- extract_section_pvalues(doc, pmcid, "body")
  
  # Extract number of authors
  num_authors <- length(xml_find_all(doc, "//contrib[@contrib-type='author']"))
  
  results <- bind_rows(abstract_pvalues, body_pvalues)
  results <- results %>% mutate(num_authors = num_authors)
  
  return(results)
}

get_all_papers <- function(head_directory_path) {
  return(list.files(head_directory_path, pattern = "\\.xml$", full.names = TRUE, recursive = TRUE))
}

# Create a function to process papers and write output to individual files
process_and_save <- function(paper_path) {
  tryCatch({
    paper_results <- process_paper(paper_path)
    if (nrow(paper_results) > 0) {
      pmcid <- str_extract(basename(paper_path), "PMC\\d+")
      output_file <- file.path(output_dir, paste0(pmcid, "_pvalues.csv"))
      write_csv(paper_results, output_file)
    }
    return(NULL)
  }, error = function(e) {
    return(list(paper_path = paper_path, error = e$message))
  })
}

# Set up parallel processing
num_cores <- detectCores() - 1
cl <- makeCluster(num_cores)
clusterExport(cl, c("process_and_save", "process_paper", "extract_section_pvalues", "get_pvalues", "clarify_title", "is_pvalue", "output_dir", "exclusion_phrases", "load_exclusion_phrases"))
clusterEvalQ(cl, {
  library(tidyverse)
  library(xml2)
  library(stringr)
})

# Get the list of all XML files to be processed
paper_paths <- get_all_papers(input_file_path)

# Process papers in parallel with a progress bar and collect any errors
errors <- pblapply(paper_paths, function(paper_path) process_and_save(paper_path), cl = cl)

# Stop the cluster
stopCluster(cl)

# Filter out any NULL entries in errors
errors <- errors[!sapply(errors, is.null)]

# Convert the errors list to a data frame with appropriate column names
if (length(errors) > 0) {
  error_df <- do.call(rbind, lapply(errors, as.data.frame))
  colnames(error_df) <- c("paper_path", "error_message")
  write_csv(as_tibble(error_df), file.path(output_dir, "errors.csv"))
}

print("P-values extraction completed. Check 'processed_data' for individual results and 'errors.csv' for any errors.")
