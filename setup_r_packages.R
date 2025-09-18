# Setup script for R packages required for Pepperweed Analysis
# Run this script in R to install all required packages

# List of required packages
required_packages <- c(
  "sf",
  "dplyr", 
  "lubridate",
  "tidyr",
  "leaflet",
  "leaflet.extras2",
  "DT",
  "htmltools",
  "knitr",
  "ggplot2",
  "plotly",
  "officer",
  "flextable",
  "webshot2"
)

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE)) {
      cat("Installing", pkg, "...\n")
      install.packages(pkg, dependencies = TRUE)
    } else {
      cat(pkg, "is already installed.\n")
    }
  }
}

# Install packages
cat("Setting up R packages for Pepperweed Analysis...\n")
install_if_missing(required_packages)

# Check if all packages are now available
cat("\nChecking package availability...\n")
all_installed <- all(sapply(required_packages, require, character.only = TRUE, quietly = TRUE))

if (all_installed) {
  cat("✅ All required packages are installed and ready!\n")
  cat("You can now render the Quarto document with: quarto render pepperweed_analysis.qmd\n")
} else {
  cat("❌ Some packages failed to install. Please check the error messages above.\n")
}

# Optional: Check Quarto installation
if (system("quarto --version", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0) {
  cat("✅ Quarto is installed and available.\n")
} else {
  cat("⚠️  Quarto is not installed. Please install Quarto from: https://quarto.org/docs/get-started/\n")
}
