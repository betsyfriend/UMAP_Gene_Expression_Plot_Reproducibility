# UMAP Gene Expression Plots for Editorial Review
# Gene-specific expression plots using a shared UMAP embedding.
# The expression data and UMAP coordinates are read from the supplied Seurat object.
# Gene-specific color gradients are defined below.

# Check the configured R and R-package versions before plotting.
REQUIRED_R_VERSION <- "4.4.2"
REQUIRED_PACKAGE_VERSIONS <- c(
  Seurat = "4.4.0",
  SeuratObject = "5.0.2",
  ggplot2 = "4.0.2",
  scales = "1.4.0",
  openxlsx = "4.2.7.1",
  viridis = "0.6.5",
  viridisLite = "0.4.2"
)

if (as.character(getRversion()) != REQUIRED_R_VERSION) {
  stop("R version mismatch: required ", REQUIRED_R_VERSION,
       "; found ", as.character(getRversion()),
       ". See README_for_Editorial_Review.md.")
}

version_mismatches <- character()
for (pkg in names(REQUIRED_PACKAGE_VERSIONS)) {
  installed_version <- tryCatch(
    as.character(utils::packageVersion(pkg)),
    error = function(e) "NOT INSTALLED"
  )
  expected_version <- unname(REQUIRED_PACKAGE_VERSIONS[[pkg]])
  if (!identical(installed_version, expected_version)) {
    version_mismatches <- c(
      version_mismatches,
      sprintf("%s: required %s, found %s", pkg, expected_version, installed_version)
    )
  }
}
if (length(version_mismatches) > 0) {
  stop("Required package versions do not match:\n",
       paste(version_mismatches, collapse = "\n"),
       "\nRun 00_Install_Required_Packages.R, restart R, and try again.")
}

library(ggplot2)
library(scales)
library(openxlsx)
library(Seurat)
library(viridis)

# 0. Automatically locate the input folder beside this R script.
# Works when launched with Rscript or sourced in R/RStudio.
get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[1]),
                                 winslash = "/", mustWork = TRUE)))
  }
  frames <- sys.frames()
  for (j in rev(seq_along(frames))) {
    if (!is.null(frames[[j]]$ofile)) {
      return(dirname(normalizePath(frames[[j]]$ofile,
                                   winslash = "/", mustWork = TRUE)))
    }
  }
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

script_dir <- get_script_dir()
input_dir <- file.path(script_dir, "input")
output_dir <- file.path(script_dir, "output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

rds_path <- file.path(input_dir, "WT_Harmony_R0.9_UMAP.rds")
gene_list_path <- file.path(input_dir, "gene_list.txt")
pdf_path <- file.path(output_dir, "UMAP_Gene_Expression_Plots_Editorial_Review.pdf")

if (!file.exists(rds_path)) stop("Seurat RDS not found: ", rds_path)
if (!file.exists(gene_list_path)) stop("Gene list not found: ", gene_list_path)

# Load the Seurat object.
WT <- readRDS(rds_path)

# 1. Extract UMAP coordinates and verify that their cells exist in RNA data.
umap_df <- as.data.frame(Embeddings(WT, reduction = "umap"))
if (anyDuplicated(rownames(umap_df))) {
  stop("Duplicate cell identifiers found in UMAP coordinates.")
}
if (!all(rownames(umap_df) %in% colnames(WT[["RNA"]]@data))) {
  stop("Some UMAP cells are missing from the RNA expression matrix.")
}

# 2. Load the two-column gene list: gene ID and gene name
gene_data <- unique(read.table(
  gene_list_path,
  header = FALSE,
  stringsAsFactors = FALSE,
  blank.lines.skip = TRUE,
  comment.char = ""
))
colnames(gene_data) <- c("gene_id", "gene_name")

# Gene-specific color palettes used for the figure batches.
# These only change visual color mapping; UMAP coordinates and RNA data are unchanged.
palette_group_1 <- c(
  "Glyma.13G130600", "Glyma.15G026400", 
  "Glyma.02G244000", "Glyma.10G183300", 
  "Glyma.15G071300", "Glyma.08G021700", 
  "Glyma.14G070800", "Glyma.13G173200", 
  "Glyma.01G084600", "Glyma.04G138700", 
  "Glyma.03G011702", "Glyma.02G034400", 
  "Glyma.10G243200", "Glyma.09G204000"
)
palette_group_2 <- c(
  "Glyma.09G025500", 
  "Glyma.10G215100", 
  "Glyma.13G114200"
)

# Calculate positions for the UMAP axis arrows
x_min <- min(umap_df$UMAP_1, na.rm = TRUE)
y_min <- min(umap_df$UMAP_2, na.rm = TRUE)
ax_origin_x <- x_min - 0.5
ax_origin_y <- y_min - 0.5
ax_len <- 3.5

# 3. Close any open graphics devices
while (dev.cur() > 1) dev.off()

# Export all gene-expression plots to a single multi-page vector PDF
pdf(pdf_path, width = 9, height = 8)

# Index for linking each output PDF page to the input gene list.
page_map <- data.frame(PDF_Page = integer(), Gene_ID = character(),
                       Gene_Name = character(), Palette_Group = character(),
                       stringsAsFactors = FALSE)

# Ensure the PDF device is closed even if an error occurs
tryCatch({
  for (i in 1:nrow(gene_data)) {
    gene_id <- gene_data$gene_id[i]
    gene_name <- gene_data$gene_name[i]

    # Skip genes that are not present in the RNA expression matrix
    if (!(gene_id %in% rownames(WT[["RNA"]]@data))) {
      message(paste("Gene not found; skipped:", gene_id))
      next
    }

    # Extract expression values for the current gene
    gene_expression <- WT[["RNA"]]@data[gene_id, rownames(umap_df)]
    umap_df$expression <- as.numeric(gene_expression)

    # Skip genes with no detected expression
    if (max(umap_df$expression, na.rm = TRUE) == 0) {
      message(paste("No detected expression; skipped:", gene_id))
      next
    }

    # Select the gene-specific color gradient.
    if (gene_id %in% palette_group_1) {
      expression_palette <- c("grey90", "grey90", "#FDD3BF", "#FDD3BF", "#CB181D")
      palette_label <- "Group 1"
    } else if (gene_id %in% palette_group_2) {
      expression_palette <- c("grey90","#FDD3BF", "#CB181D")
      palette_label <- "Group 2"
    } else {
      stop("No verified palette group for gene: ", gene_id,
           ". Check the original plotting settings before adding this gene.")
    }

    # Plot low-expression cells first so high-expression cells remain visible
    umap_df_sorted <- umap_df[order(umap_df$expression, decreasing = FALSE), ]

    p <- ggplot(umap_df_sorted, aes(x = UMAP_1, y = UMAP_2)) +
      geom_point(data = subset(umap_df_sorted, expression == 0),
                 color = "grey90", size = 0.5) +
      geom_point(data = subset(umap_df_sorted, expression > 0),
                 aes(color = expression),
                 size = 0.6, alpha = 0.8) +
      scale_color_gradientn(
        colours = expression_palette,
        name = "Expression"
      ) +
      theme_void(base_size = 10) +
      theme(
        legend.title = element_text(size = 8),
        legend.text = element_text(size = 7),
        plot.title = element_text(size = 10, face = "bold", hjust = 0.5),
        plot.margin = margin(t = 20, r = 20, b = 20, l = 20)
      ) +
      labs(title = paste(gene_name, gene_id)) +
      # UMAP 1 arrow
      geom_segment(aes(x = ax_origin_x, y = ax_origin_y,
                       xend = ax_origin_x + ax_len, yend = ax_origin_y),
                   linewidth = 0.6, color = "black",
                   arrow = arrow(length = unit(0.12, "cm"), type = "closed"),
                   inherit.aes = FALSE) +
      # UMAP 2 arrow
      geom_segment(aes(x = ax_origin_x, y = ax_origin_y,
                       xend = ax_origin_x, yend = ax_origin_y + ax_len),
                   linewidth = 0.6, color = "black",
                   arrow = arrow(length = unit(0.12, "cm"), type = "closed"),
                   inherit.aes = FALSE) +
      # UMAP 1 label
      annotate("text", x = ax_origin_x + (ax_len / 2), y = ax_origin_y - 0.7,
               label = "UMAP 1", size = 3.2, fontface = "bold", hjust = 0.5) +
      # UMAP 2 label
      annotate("text", x = ax_origin_x - 0.8, y = ax_origin_y + (ax_len / 2),
               label = "UMAP 2", size = 3.2, fontface = "bold", angle = 90, vjust = 0.5) +
      coord_cartesian(
        xlim = c(ax_origin_x - 1.8, max(umap_df$UMAP_1, na.rm = TRUE) + 1),
        ylim = c(ax_origin_y - 1.8, max(umap_df$UMAP_2, na.rm = TRUE) + 1),
        clip = "off"
      )

    print(p)
    page_map <- rbind(page_map, data.frame(
      PDF_Page = nrow(page_map) + 1L,
      Gene_ID = gene_id,
      Gene_Name = gene_name,
      Palette_Group = palette_label,
      stringsAsFactors = FALSE
    ))
  }
}, finally = {
  # Always close the PDF device
  dev.off()
})

# Save the mapping of PDF pages to genes (helpful for editorial review).
write.csv(page_map, file.path(output_dir, "UMAP_PDF_Page_to_Gene.csv"),
          row.names = FALSE, na = "")

# Record the R environment and loaded package versions for this run.
writeLines(capture.output(sessionInfo()),
           con = file.path(output_dir, "R_Session_Info.txt"))

message("All gene-expression plots have been saved to: ", pdf_path)
message("Page index: ", file.path(output_dir, "UMAP_PDF_Page_to_Gene.csv"))
message("Software versions: ", file.path(output_dir, "R_Session_Info.txt"))
