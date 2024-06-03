library(tidyverse)

# Set the file path to the combined CSV file
combined_file_path <- "combined_output/combined_pvalues.csv"

# Read the data
pvalues_data <- read_csv(combined_file_path)

pvalues_data <- pvalues_data %>%
  drop_na()

# keep only those with 3dp
pvalues_data <- pvalues_data %>%
  filter(str_detect(as.character(p_value), "^0\\.\\d{3}$"))

# Convert p_value to numeric
pvalues_data <- pvalues_data %>%
  mutate(p_value = as.numeric(p_value)) %>%
  filter(!is.na(p_value)) %>%
  filter(operator == "=")


categorize_authors <- function(num_authors) {
  if (num_authors == 0) {
    return("0")
  } else if (num_authors == 1) {
    return("1")
  } else if (num_authors == 2) {
    return("2")
  } else if (num_authors == 3) {
    return("3")
  } else if (num_authors == 4) {
    return("4")
  } else if (num_authors >= 5 & num_authors <= 10) {
    return("5-10")
  } else if (num_authors > 10 & num_authors <= 50) {
    return("10-50")
  } else {
    return(">50")
  }
}

# Add the contributors column based on num_authors
pvalues_data <- pvalues_data %>%
  mutate(
    contributors = factor(
      sapply(num_authors, categorize_authors),
      levels = c("0", "1", "2", "3", "4", "5-10", "10-50", ">50"),
      ordered = TRUE
    )
  )


# Plot the data
ggplot(subset(pvalues_data, num_authors < 5), aes(x = p_value)) +
  geom_histogram(binwidth = 0.001) +
  facet_wrap(.~contributors, scales = "free_y") +
  theme_minimal() +
  labs(
    title = "Distribution of p-values with the '=' operator",
    x = "p-value",
    y = "Frequency"
  ) + scale_y_log10()

ggplot(subset(pvalues_data, num_authors < 5), aes(x = p_value,  color = contributors)) +
  geom_density(bw = 0.004) +
  theme_minimal() +
  labs(
    title = "Distribution of p-values with the '=' operator",
    x = "p-value",
    y = "Frequency"
  ) + scale_y_log10() + xlim(c(0.0, 0.2))


ggplot(subset(pvalues_data, num_authors < 5), aes(x = p_value, color = contributors)) +
  stat_ecdf(geom = "step") +
  labs(title = "Empirical Cumulative Distribution Function of p-values",
       x = "p-value",
       y = "ECDF") +
  theme_minimal()

