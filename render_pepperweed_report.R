# Pepperweed Analysis Report Rendering Function
# This script provides functions to render the pepperweed analysis in multiple formats

library(quarto)
library(officer)
library(flextable)

#' Render Pepperweed Analysis Report
#' 
#' This function renders the pepperweed analysis Quarto document to both HTML and Word formats.
#' It also creates a custom reference document for Word formatting if it doesn't exist.
#' 
#' @param input_file Path to the Quarto document (default: "pepperweed_analysis.qmd")
#' @param output_dir Directory to save output files (default: ".")
#' @param create_reference_doc Whether to create a custom Word reference document (default: TRUE)
#' @param render_html Whether to render HTML format (default: TRUE)
#' @param render_word Whether to render Word format (default: TRUE)
#' @param open_output Whether to open the output files after rendering (default: FALSE)
#' 
#' @return List containing paths to generated files
#' @export
render_pepperweed_report <- function(
  input_file = "pepperweed_analysis.qmd",
  output_dir = ".",
  create_reference_doc = TRUE,
  render_html = TRUE,
  render_word = TRUE,
  open_output = FALSE
) {
  
  # Check if input file exists
  if (!file.exists(input_file)) {
    stop("Input file '", input_file, "' not found.")
  }
  
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Create custom reference document if requested and doesn't exist
  reference_doc <- file.path(output_dir, "custom-reference.docx")
  if (create_reference_doc && !file.exists(reference_doc)) {
    cat("Creating custom Word reference document...\n")
    create_word_reference_doc(reference_doc)
  }
  
  # Initialize results list
  results <- list()
  
  # Render HTML format
  if (render_html) {
    cat("Rendering HTML format...\n")
    tryCatch({
      html_output <- quarto_render(
        input = input_file,
        output_format = "html"
      )
      results$html <- html_output
      cat("✅ HTML rendered successfully:", html_output, "\n")
    }, error = function(e) {
      cat("❌ HTML rendering failed:", e$message, "\n")
      results$html_error <- e$message
    })
  }
  
  # Render Word format
  if (render_word) {
    cat("Rendering Word format...\n")
    tryCatch({
      # Check if reference document exists
      if (file.exists(reference_doc)) {
        cat("Using custom reference document:", reference_doc, "\n")
      }
      
      word_output <- quarto_render(
        input = input_file,
        output_format = "docx"
      )
      results$word <- word_output
      cat("✅ Word document rendered successfully:", word_output, "\n")
    }, error = function(e) {
      cat("❌ Word rendering failed:", e$message, "\n")
      results$word_error <- e$message
    })
  }
  
  # Open output files if requested
  if (open_output) {
    if (!is.null(results$html) && file.exists(results$html)) {
      system(paste("open", results$html))
    }
    if (!is.null(results$word) && file.exists(results$word)) {
      system(paste("open", results$word))
    }
  }
  
  # Print summary
  cat("\n", paste(rep("=", 50), collapse=""), "\n")
  cat("RENDERING SUMMARY\n")
  cat(paste(rep("=", 50), collapse=""), "\n")
  if (!is.null(results$html)) {
    cat("📄 HTML Report:", results$html, "\n")
  }
  if (!is.null(results$word)) {
    cat("📄 Word Report:", results$word, "\n")
  }
  if (!is.null(results$html_error)) {
    cat("❌ HTML Error:", results$html_error, "\n")
  }
  if (!is.null(results$word_error)) {
    cat("❌ Word Error:", results$word_error, "\n")
  }
  cat(paste(rep("=", 50), collapse=""), "\n")
  
  return(results)
}

#' Create Custom Word Reference Document
#' 
#' Creates a custom Word reference document with professional formatting
#' for the pepperweed analysis report.
#' 
#' @param output_path Path where to save the reference document
#' @return Path to the created reference document
create_word_reference_doc <- function(output_path = "custom-reference.docx") {
  
  # Create a new document
  doc <- read_docx()
  
  # Add title page content
  doc <- doc %>%
    body_add_par("Pepperweed Analysis Report", style = "heading 1") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("Lower Owens River Project", style = "heading 2") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("Lepidium latifolium Distribution Analysis", style = "heading 3") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("Noxious Weeds Monitoring Program", style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("This document contains the complete analysis of pepperweed populations", style = "Normal") %>%
    body_add_par("in the Owens Valley area, including spatial distribution, population", style = "Normal") %>%
    body_add_par("trends, and management recommendations.", style = "Normal")
  
  # Add page break
  doc <- doc %>%
    body_add_break() %>%
    body_add_par("Table of Contents", style = "heading 1") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("(Table of contents will be automatically generated)", style = "Normal")
  
  # Save the document
  print(doc, target = output_path)
  
  cat("Custom Word reference document created:", output_path, "\n")
  return(output_path)
}

#' Quick Render Function
#' 
#' A simplified function for quick rendering of both formats
#' 
#' @param open_files Whether to open the generated files (default: TRUE)
quick_render <- function(open_files = TRUE) {
  render_pepperweed_report(
    open_output = open_files,
    create_reference_doc = TRUE
  )
}

# Example usage and documentation
cat("Pepperweed Report Rendering Functions Loaded\n")
cat(paste(rep("=", 50), collapse=""), "\n")
cat("Available functions:\n")
cat("• render_pepperweed_report() - Full control over rendering\n")
cat("• quick_render() - Quick render with default settings\n")
cat("• create_word_reference_doc() - Create custom Word template\n")
cat("\n")
cat("Example usage:\n")
cat("  # Quick render (recommended)\n")
cat("  quick_render()\n")
cat("\n")
cat("  # Custom render\n")
cat("  render_pepperweed_report(\n")
cat("    render_html = TRUE,\n")
cat("    render_word = TRUE,\n")
cat("    open_output = TRUE\n")
cat("  )\n")
cat(paste(rep("=", 50), collapse=""), "\n")
