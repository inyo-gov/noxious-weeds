# Create a custom Word reference document for better formatting
# This script creates a reference.docx file that Quarto will use for Word output

library(officer)
library(flextable)
library(magrittr)

# Create a new document
doc <- read_docx()

# Set document properties
doc <- doc %>%
  body_add_par("Pepperweed Analysis Template", style = "heading 1") %>%
  body_add_par("This is a template document for formatting the pepperweed analysis report.", style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("Key Features:", style = "heading 2") %>%
  body_add_par("• Professional formatting", style = "Normal") %>%
  body_add_par("• Table of contents", style = "Normal") %>%
  body_add_par("• Numbered sections", style = "Normal") %>%
  body_add_par("• Custom styles for data tables", style = "Normal")

# Save the reference document
print(doc, target = "custom-reference.docx")

cat("Reference document 'custom-reference.docx' created successfully!\n")
cat("This document will be used as a template for Word output formatting.\n")
