# One-time environment setup for UMAP editorial-review reproduction.
# This file installs the specified package versions ONLY if needed.
# Run this ONCE in a fresh R 4.4.2 session, before the plotting script.
# The plotting script itself does NOT install or update packages.
#
# Windows R 4.4.2 installer:
# https://cran.r-project.org/bin/windows/base/old/4.4.2/R-4.4.2-win.exe
# On Windows, archived source packages may require Rtools44:
# https://cran.r-project.org/bin/windows/Rtools/

EXPECTED_R_VERSION <- "4.4.2"
if (as.character(getRversion()) != EXPECTED_R_VERSION) {
  stop("Install R ", EXPECTED_R_VERSION, " first. Current R: ",
       as.character(getRversion()))
}

options(repos = c(CRAN = "https://cloud.r-project.org"))

# Install the remotes helper only when it is not already available.
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes", repos = getOption("repos"))
}

# Requested package versions for the plotting workflow.
# Some packages are dependencies of others; install in this order.
package_versions <- c(
  viridisLite = "0.4.2",
  scales = "1.4.0",
  openxlsx = "4.2.7.1",
  ggplot2 = "4.0.2",
  viridis = "0.6.5",
  SeuratObject = "5.0.2",
  Seurat = "4.4.0"
)

for (pkg in names(package_versions)) {
  version_needed <- unname(package_versions[[pkg]])
  installed <- if (requireNamespace(pkg, quietly = TRUE)) {
    as.character(utils::packageVersion(pkg))
  } else {
    NA_character_
  }
  if (identical(installed, version_needed)) {
    message("Already correct: ", pkg, " ", version_needed)
    next
  }
  message("Installing ", pkg, " ", version_needed,
          " (installed: ", ifelse(is.na(installed), "none", installed), ")")
  remotes::install_version(
    package = pkg,
    version = version_needed,
    repos = getOption("repos"),
    dependencies = NA,
    upgrade = "never",
    type = "source"
  )
}

# Verify that all requested versions are installed after dependencies resolve.
incorrect <- character()
for (pkg in names(package_versions)) {
  found <- tryCatch(as.character(utils::packageVersion(pkg)),
                    error = function(e) "NOT INSTALLED")
  want <- unname(package_versions[[pkg]])
  message(sprintf("%-13s required=%-9s installed=%s", pkg, want, found))
  if (!identical(found, want)) {
    incorrect <- c(incorrect, paste0(pkg, " (required ", want,
                                    ", installed ", found, ")"))
  }
}
if (length(incorrect)) {
  stop("Version validation failed: ", paste(incorrect, collapse = "; "),
       ". Resolve the installation and rerun in a fresh R session.")
}
message("Required packages match. Restart R, then run the plotting script.")
