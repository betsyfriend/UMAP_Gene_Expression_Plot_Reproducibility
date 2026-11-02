# UMAP Gene Expression Plots — Source Code for Editorial Review

## Purpose

This folder provides the R script and supporting files for generating the gene-specific UMAP expression plots used in the manuscript. The script reads the supplied Seurat object, uses its `umap` embedding and RNA assay `@data` expression matrix, and produces a separate UMAP panel for each gene in the input list.

All panels share the same UMAP coordinates, so each cell appears at the same location across plots. For each panel, expression values are extracted independently for the corresponding gene. The plotting parameters and gene-specific color gradients are specified below to support independent examination of the figures.

## Folder structure and input files

```text
UMAP_Gene_Expression_Plot_Reproducibility/
├── input/
│   ├── WT_Harmony_R0.9_UMAP.rds
│   └── gene_list.txt
├── 00_Install_Required_Packages.R
├── UMAP_Gene_Expression_Plotting.R
├── README_for_Editorial_Review.md
└── output/                         (created automatically)
```

- **`WT_Harmony_R0.9_UMAP.rds`**: Seurat object containing the `umap` reduction and RNA assay `@data` expression matrix. Place the RDS file used for the submitted figures in the `input/` folder.
- **`gene_list.txt`**: A two-column, headerless, tab-separated text file containing 17 genes. Column 1 contains the Glyma gene ID, and column 2 contains the gene name. Blank lines between groups are ignored. No header row or group labels are needed.
- **`00_Install_Required_Packages.R`**: Script for installing the specified R package versions when needed.
- **`UMAP_Gene_Expression_Plotting.R`**: Main script for generating all gene-specific UMAP expression plots.
- **`README_for_Editorial_Review.md`**: Instructions for installing software, running the analysis, and interpreting the outputs.
- **`output/`**: Folder created automatically to store the resulting plots and accompanying records.

## Software versions and installation

The plotting workflow is configured for the following software versions:

| Software | Version |
|---|---|
| R | **4.4.2** (2024-10-31 ucrt) |
| Seurat | **4.4.0** |
| SeuratObject | **5.0.2** |
| ggplot2 | **4.0.2** |
| scales | **1.4.0** |
| openxlsx | **4.2.7.1** |
| viridis | **0.6.5** |
| viridisLite | **0.4.2** |

### Step 1 — Install R

For Windows, download and install R 4.4.2:

https://cran.r-project.org/bin/windows/base/old/4.4.2/R-4.4.2-win.exe

RStudio Desktop may optionally be used to open and run the scripts:

https://posit.co/downloads/

If multiple R installations are available, select R 4.4.2.

### Step 2 — Install the required R packages

Start R 4.4.2 in the project folder and run:

```r
source("00_Install_Required_Packages.R")
```

Alternatively, run the installer from a terminal in the project folder:

```bash
Rscript 00_Install_Required_Packages.R
```

The installer uses `remotes::install_version()` to install the specified package versions and skips packages already installed at the required versions. Package installation is a separate step and is not initiated automatically by the plotting script.

An internet connection is required to download missing packages. On Windows, some source-package installations may require Rtools44:

https://cran.r-project.org/bin/windows/Rtools/

### Step 3 — Check the software versions

Restart R and run:

```r
R.version.string

sapply(
  c("Seurat", "SeuratObject", "ggplot2", "scales", "openxlsx", "viridis", "viridisLite"),
  function(pkg) as.character(packageVersion(pkg))
)
```

The plotting script also checks the R and package versions and stops with an explanatory message if a required version does not match.

## Running the plotting script

Place `WT_Harmony_R0.9_UMAP.rds` and `gene_list.txt` in the `input/` folder.

**Option A — RStudio:** Open `UMAP_Gene_Expression_Plotting.R` and select **Source** to run the complete script.

**Option B — Terminal:** Run the following command from the project folder:

```bash
Rscript UMAP_Gene_Expression_Plotting.R
```

The script locates `input/` relative to the script location, so machine-specific file paths do not need to be changed. If running selected lines manually in RStudio rather than sourcing the entire file, first set the working directory to the project folder.

## Output files

The script creates the `output/` folder and writes the following files:

1. **`UMAP_Gene_Expression_Plots_Editorial_Review.pdf`** — A vector PDF with one page per gene detected in the RNA expression matrix with nonzero expression. Each page title includes the gene name and Glyma gene ID, for example, `GmLOX1 Glyma.15G026400`. Pages follow the order in `gene_list.txt`.
2. **`UMAP_PDF_Page_to_Gene.csv`** — A table linking each PDF page to its gene ID, gene name, and assigned color-palette group. Genes absent from the matrix or with all-zero expression are skipped and reported in the R console.
3. **`R_Session_Info.txt`** — A record of the R version, loaded packages, and package versions for the plotting run.

The output PDF uses a **9 × 8 in** canvas and the specified point sizes, opacity, gray background, drawing order, titles, axes, and annotation settings.

## Gene-specific color gradients

Gene-specific color gradients are assigned by **Glyma gene ID**. The gradients affect only the visualization of expression values; they do not change the expression measurements or UMAP cell positions.

### Group 1 — 14 genes; five color stops

```r
c("grey90", "grey90", "#FDD3BF", "#FDD3BF", "#CB181D")
```

| Gene ID | Gene name |
|---|---|
| Glyma.13G130600 | GmEPCspecial1 |
| Glyma.15G026400 | GmLOX1 |
| Glyma.02G244000 | GmGSR1 |
| Glyma.10G183300 | GmPHO1 |
| Glyma.15G071300 | GmHUP54 | 
| Glyma.08G021700 | Gm3xHMG-box1 |
| Glyma.14G070800 | GmPRX9a |
| Glyma.13G173200 | GmA6 |
| Glyma.01G084600 | GmEAP |
| Glyma.04G138700 | GmLTPG1 |
| Glyma.03G011702 | GmUBAL1 |
| Glyma.02G034400 | GmVEN4 |
| Glyma.10G243200 | GmDMC1 |
| Glyma.09G204000 | GmMSP2 |

### Group 2 — 3 genes; three color stops

```r
c("grey90", "#FDD3BF", "#CB181D")
```

| Gene ID | Gene name |
|---|---|
| Glyma.09G025500 | GmTDM1a |
| Glyma.10G215100 | GmPS1 |
| Glyma.13G114200 | GmTES |

Only genes with an explicitly defined palette are plotted. For each gene, `scale_color_gradientn()` maps positive expression values according to that gene's observed expression range. The colors therefore represent **gene-specific relative expression**, not a single calibrated absolute-expression scale shared by all genes.

## Explanation of similarities between UMAP panels

All gene-expression panels use **identical UMAP coordinates**. Accordingly, each cell occupies the same position in every panel, and the overall shape of the UMAP is identical across genes.

For each gene, cells with an expression value of exactly zero are displayed in `grey90`, whereas cells with positive expression are colored according to the gradient assigned to that gene. Therefore, the particular cells forming the zero-expression gray background may differ between panels. In palettes containing `grey90`, some cells with low but positive expression may also appear light gray.

Some genes are expressed in overlapping cell populations. Consequently, their highlighted cell distributions may partially overlap, leading to visually similar UMAP panels, particularly when a large proportion of cells appears gray. Nevertheless, **each panel is generated from the expression values of its specified gene**, rather than from a previously rendered image of another gene.

The full distributions of highlighted cells and expression intensities should be examined when comparing different panels, rather than relying solely on cropped regions. Where the same marker gene is displayed in both **Fig. 2** and **Fig. S2**, matching expression patterns are expected.

## Reproducibility and verification

The plotting script, input gene list, specified palette assignments, PDF page-to-gene table, and software session record provide the information needed to reproduce and inspect the UMAP expression panels. The gene ID and gene name shown on each PDF page enable direct identification of the corresponding expression data.
