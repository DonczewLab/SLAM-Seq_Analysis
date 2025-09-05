#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(tibble)
})

# -------------------------
# Args
# -------------------------
#  1: samples_csv
#  2: scer_merge_totalreadcount.tsv
#  3: scer_merge_onetcreadcount.tsv
#  4: scer_merge_twotcreadcount.tsv
#  5: outdir (e.g., results/processed)
#  6: use_spikein ("true"/"false")
#  7: spikein_merge_totalreadcount.tsv (optional if use_spikein=false)
#  8: spikein_merge_onetcreadcount.tsv (optional if use_spikein=false)
#  9: spikein_merge_twotcreadcount.tsv (optional if use_spikein=false)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 6) {
  stop("Expected at least 6 arguments:
  1) samples_csv
  2) scer_merge_totalreadcount.tsv
  3) scer_merge_onetcreadcount.tsv
  4) scer_merge_twotcreadcount.tsv
  5) outdir
  6) use_spikein
 [7-9 optional spike-in merge files when use_spikein=true]", call. = FALSE)
}

samples_csv <- args[1]
scer_total_path <- args[2]
scer_oneTC_path <- args[3]
scer_twoTC_path <- args[4]
outdir <- args[5]
use_spikein <- tolower(args[6]) %in% c("true","t","1","yes","y")

spike_total_path <- if (use_spikein && length(args) >= 7) args[7] else NA_character_
spike_oneTC_path <- if (use_spikein && length(args) >= 8) args[8] else NA_character_
spike_twoTC_path <- if (use_spikein && length(args) >= 9) args[9] else NA_character_

dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# -------------------------
# Helpers
# -------------------------

read_samples <- function(path) {
  read.delim(path, sep = ",", header = TRUE, stringsAsFactors = FALSE) |>
    as_tibble() |>
    mutate(sample = as.character(sample)) |>
    column_to_rownames("sample")
}

# The alleyoop merge TSVs have 3 header lines; the first real header row starts at line 4.
# They include a "Name" column plus columns named by input basenames (e.g., "{sample}_trimmed.fastq").
# We:
#   - skip first 3 lines
#   - make rownames from "Name"
#   - strip the "_trimmed.fastq" suffix so columns become the {sample} IDs
#   - select/reorder to match sample_names
read_merge_matrix <- function(path, sample_names) {
  if (!file.exists(path)) stop(paste("Missing file:", path))
  df <- read.delim(path, sep = "\t", header = TRUE, stringsAsFactors = FALSE, skip = 3) |>
    as_tibble()

  if (!"Name" %in% names(df)) {
    stop(sprintf("Expected column 'Name' in merged file: %s", path))
  }

  df <- df |>
    column_to_rownames("Name")

  # Normalize column names back to sample IDs
  colnames(df) <- gsub("_trimmed\\.fastq$", "", colnames(df))

  # Keep only known samples (and in exact order)
  missing_cols <- setdiff(sample_names, colnames(df))
  if (length(missing_cols) > 0) {
    stop(sprintf("File %s is missing columns for samples: %s",
                 path, paste(missing_cols, collapse = ", ")))
  }

  df2 <- df[, sample_names, drop = FALSE]
  as.data.frame(df2)
}

write_df <- function(x, path) {
  write.csv(as.data.frame(x), file = path, quote = TRUE)
}

# -------------------------
# Load samples
# -------------------------
samples_tbl <- read_samples(samples_csv)
sample_names <- rownames(samples_tbl)

# -------------------------
# SCER (primary) matrices
# -------------------------
total_scer <- read_merge_matrix(scer_total_path, sample_names)
oneTC_scer <- read_merge_matrix(scer_oneTC_path,  sample_names)
twoTC_scer <- read_merge_matrix(scer_twoTC_path,  sample_names)

write_df(total_scer, file.path(outdir, "totalreadcounts.csv"))
write_df(oneTC_scer, file.path(outdir, "onetcreadcounts.csv"))
write_df(twoTC_scer, file.path(outdir, "twotcreadcounts.csv"))

# Total-readcount normalization factors (reads / 10,000,000)
total_norm_factors <- colSums(total_scer) / 1e7
total_norm_factors_df <- data.frame(totalreadcount_normfactors = total_norm_factors)
write_df(total_norm_factors_df, file.path(outdir, "totalreadcount_normalization_factors.csv"))

# Apply library-size normalization to TwoTC matrix
# Recycle by row to divide each column by its factor
total_norm_vec <- t(as.data.frame(total_norm_factors))  # 1 x N
total_norm_twoTC <- sweep(twoTC_scer, 2, as.numeric(total_norm_factors), FUN = "/")
write_df(total_norm_twoTC, file.path(outdir, "totalreadcount_normalized_twotcreadcounts.csv"))

# -------------------------
# SPIKE-IN (optional)
# -------------------------
if (use_spikein) {
  if (any(!file.exists(c(spike_total_path, spike_oneTC_path, spike_twoTC_path)))) {
    stop("use_spikein=TRUE but one or more spike-in merge files are missing.", call. = FALSE)
  }

  total_spike <- read_merge_matrix(spike_total_path, sample_names)
  oneTC_spike <- read_merge_matrix(spike_oneTC_path,  sample_names)
  twoTC_spike <- read_merge_matrix(spike_twoTC_path,  sample_names)

  write_df(total_spike, file.path(outdir, "totalreadcounts_spikein.csv"))
  write_df(oneTC_spike, file.path(outdir, "onetcreadcounts_spikein.csv"))
  write_df(twoTC_spike, file.path(outdir, "twotcreadcounts_spikein.csv"))

  # Spike-in normalization factors (spike reads / 1,000,000)
  spike_norm_factors <- colSums(total_spike) / 1e6
  spike_norm_factors_df <- data.frame(spikein_normfactors = spike_norm_factors)
  write_df(spike_norm_factors_df, file.path(outdir, "spikein_normalization_factors.csv"))

  # Apply spike-in normalization to primary TwoTC matrix
  spike_norm_twoTC <- sweep(twoTC_scer, 2, as.numeric(spike_norm_factors), FUN = "/")
  write_df(spike_norm_twoTC, file.path(outdir, "spikein_normalized_twotcreadcounts.csv"))
}
