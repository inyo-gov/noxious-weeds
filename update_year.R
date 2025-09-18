# Script to update the report for a new year
# Usage: Rscript update_year.R 2026

# Get the new year from command line argument
args <- commandArgs(trailingOnly = TRUE)
if(length(args) == 0) {
  stop("Please provide a year: Rscript update_year.R 2026")
}

new_year <- as.numeric(args[1])
if(is.na(new_year) || new_year < 2025) {
  stop("Please provide a valid year >= 2025")
}

# Read the current index.qmd file
index_content <- readLines("index.qmd")

# Update the current_year parameter
index_content <- gsub("current_year: 2025", paste0("current_year: ", new_year), index_content)

# Write the updated file
writeLines(index_content, "index.qmd")

cat("Updated index.qmd for year", new_year, "\n")
cat("Now run: quarto render index.qmd\n")
