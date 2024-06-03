library(tidyverse)
library(xml2)
library(stringr)
library(parallel)
library(pbapply)
library(optparse)

# Define options
option_list <- list(
  make_option(c("-i", "--input"), type = "character", default = "raw_data/xml_files/", 
              help = "Input directory with XML files", metavar = "character"),
  make_option(c("-o", "--output"), type = "character", default = "processed_data_rr", 
              help = "Output directory", metavar = "character"),
  make_option(c("-e", "--exclusion"), type = "character", default = "exclusion_phrases_rr.txt", 
              help = "File with exclusion phrases", metavar = "character"),
  make_option(c("-c", "--context"), action = "store_true", default = FALSE, 
              help = "Include context")
)

opt <- parse_args(OptionParser(option_list = option_list))

input_file_path <- opt$input
output_dir <- opt$output
exclusion_file <- opt$exclusion
include_context <- opt$context

dir.create(output_dir, showWarnings = FALSE)

# Function to clean up titles extracted from XML tags
clarify_title <- function(tag) {
  title <- xml_text(tag)
  title <- str_replace_all(title, "[\r\n]", " ")
  return(title)
}

# Function to extract relevant sentences from text
get_relevant_sentences <- function(text) {
  pattern <- "data available\\s+.*?\\s+request"
  sentences <- unlist(strsplit(text, "(?<=[.!?])\\s*(?=[A-Z])", perl = TRUE))
  relevant_sentences <- sentences[str_detect(tolower(sentences), pattern)]
  return(relevant_sentences)
}

load_exclusion_phrases <- function(file) {
  return(tolower(read_lines(file)))
}

exclusion_phrases <- load_exclusion_phrases(exclusion_file)

extract_section_sentences <- function(doc, pmcid, section) {
  section_text <- xml_text(xml_find_all(doc, paste0("//", section)))
  sentences <- get_relevant_sentences(section_text)
  results <- tibble()
  
  for (sentence in sentences) {
    # Exclude sentences with exclusion phrases
    if (any(str_detect(tolower(sentence), exclusion_phrases))) {
      next
    }
    
    temp_results <- tibble(
      sentence = sentence,
      pmcid = pmcid,
      section = section
    )
    results <- bind_rows(results, temp_results)
  }
  
  return(results)
}

process_paper <- function(paper_path) {
  doc <- read_xml(paper_path)
  pmcid <- xml_text(xml_find_first(doc, "//article-id[@pub-id-type='pmc']"))
  
  abstract_sentences <- extract_section_sentences(doc, pmcid, "abstract")
  body_sentences <- extract_section_sentences(doc, pmcid, "body")
  
  return(bind_rows(abstract_sentences, body_sentences))
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
      output_file <- file.path(output_dir, paste0(pmcid, "_sentences.csv"))
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
clusterExport(cl, c("process_and_save", "process_paper", "extract_section_sentences", "get_relevant_sentences", "clarify_title", "output_dir", "exclusion_phrases", "load_exclusion_phrases"))
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

print("Sentences extraction completed. Check 'processed_data' for individual results and 'errors.csv' for any errors.")
