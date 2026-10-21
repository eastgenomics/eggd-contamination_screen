# eggd_contamination-screen
DNANexus app wrapper around [contamination-screen.py](https://github.com/eastgenomics/contamination-screen/)

## What does this app do?
Runs `contamination-screen.py` on pairs of VCFs, given a batch of VCFs, a samplesheet (used to infer plate layout) and the output from verifyBamID.

## What are the typical use cases for this app?
The typical use case is for running regular pairwise contamination checking, per run, as part of routine production analyses.

## What are the inputs?

### Required arguments

- `-ivcfs`: VCF file. Repeatable.
- `-iverifybamid`: verifyBamID results.

### Optional arguments

- `-isamplesheet`: SampleSheet for the run-of-origin; used to infer plate layout. If not provided, the output will be sorted on sample name alphanumerically.
- `-iplots`: Boolean. If submitted, AF log2-ratio plots will be generated. The `-ibin_width` argument can be configured to change bin width. (Default: false)
- `-ibin_width`: Controls bin-width on VAF log2-ratio histograms. (Default: 0.2)
- `-imin_af`: Minimum VAF in both samples for a variant to be informative. (Default: 0.03)
- `-imin_dp`: Minimum read depth (`FORMAT/DP`) to retain a variant. The filter expression is `DP < min_dp`, so `DP=99` is retained by default - this matches the clinical pipeline expression `FORMAT/DP<99`. (Default: 99)
- `-imax_gnomad`: Exclude variants with gnomAD AF greater than, or equal to, this value. Very common variants (AF > 0.40) produce false 2:1 ratio signals when one sample is hom-alt and the other is het. Set to 1.0 to disable. (Default: 0.4)
- `-imin_shared`: Minimum number of informative shared variants required before assessing a pair. (Default: 10)
- `-ifreemix_threshold`: Minimum recipient FREEMIX fraction (0–1) required for flagging. (Default: 0.15)
- `-inon_unity_count`: Flag a pair if the non-unity peak contains at least this many variants. (Default: 10)
- `-in_shared_z`: Flag a pair only if the within-run z-score of shared-variant count meets or exceeds this threshold (computed across all pairs in the run). Flagging occurs only when the `-inon_unity_count` threshold is also met. (Default: 2.0)
- `-iinclude_non_pass`: Include non-PASS variants. (Default: false)
- `-imax_output`: Maximum number of flagged pairs to write detail TSVs and plots for, ranked by non-unity count. Set to 0 for no limit. (Default: 0)
- `-ithreads`: Number of parallel threads for pairwise comparisons. (Default: 8)
- `-iverbose`: Enable debug logging. (Default: false)

## What are the outputs?

- `summary`: contamination-screen summary of pairwise comparisons. Saved as `summary.tsv`.
- `matrix`: Matrix of shared variants across pairs. Saved as `matrix.tsv`.
- `filtered_vcfs`: Filtered VCFs and index files.
- `flagged_pairs`: Flagged-pair output TSVs - one file is produced per flagged pair.
- `plots`: VAF log2-ratio histogram plots - one file is produced per flagged pair.

## How to run this app from command line?

### Minimal example

```
dx run app-eggd_contamination-screen \
  -iverifybamid=project-xxxxx:file-xxxxx \
  -ivcfs=project-xxxxx:file-xxxxx \
  [[-ivcfs=...]]
```

### With all possible settings

```
dx run app-eggd_contamination-screen \
 -ivcfs=project-xxxxxx:file-xxxxxx \
 [[-ivcfs=...]] \
 -iverifybamid=project-xxxxx:file-xxxxx \
 -isamplesheet=project-xxxxx:file-xxxxx \
 -iverbose \
 -iinclude_non_pass \
 -iplots \
 -ibin_width=0.1 \
 -imin_af=0.1 \
 -imin_dp=50 \
 -imax_gnomad=0.1 \
 -imin_shared=20 \
 -ifreemix_threshold=0.2 \
 -inon_unity_count=15 \
 -in_shared_z=2.5 \
 -imax_output=20 \
 -ithreads=12
```
