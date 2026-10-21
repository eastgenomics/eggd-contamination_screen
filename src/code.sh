#!/bin/bash
# eggd-contamination_screen

set -e -x -o pipefail

main() {
    pip3 install /home/dnanexus/python_packages/*.whl
    dx-download-all-inputs

    # Index all the VCFs
    VCF_DIR="/home/dnanexus/in/vcfs/"
    find $VCF_DIR -type f -name "*.vcf.gz" -exec mv -t $VCF_DIR {} +
    find $VCF_DIR -name "*.vcf.gz" -print0 | xargs -0 -P 32 -I {} bcftools index -t {}

    SAMPLESHEET=$(find /home/dnanexus/in/samplesheet/ -name "*.csv")
    if [[ -e $SAMPLESHEET ]]; then
        # Get plate layout from SampleSheet.csv
        # output format:
        # Sample	custom_content_samplesheet_wells-well_column	custom_content_samplesheet_wells-well_row
        # <sample_name>	1	A
        # <sample_name>	1	B
        # ...
        # contamination-screen.py needs the data to be multiqc-style formatted, hence the column names
        DATA_START=$(grep -n Sample_ID $SAMPLESHEET | cut -f1 -d":")
        tail -n+$(bc -l <<< "$DATA_START + 1") $SAMPLESHEET > samplesheet_data.csv
        echo -e "Sample\tcustom_content_samplesheet_wells-well_column\tcustom_content_samplesheet_wells-well_row" > plate_layout.tsv
        cut -f1,4 -d"," samplesheet_data.csv | sed -E "s:(.+),([A-H])([0-9]+):\1\t\3\t\2:g" >> plate_layout.tsv
   fi

    # Parse VerifyBAMID data
    # output format:
    # Sample	FREEMIX
    # <sample_name>	<freemix value>
    # contamination-screen.py needs the data to be multiqc-style formatted, hence the column
    # names and conversion of freemix values from % to fraction
    VBI=$(find /home/dnanexus/in/verifybamid/ -name "*.txt")
    awk -f /home/dnanexus/parse_verifybamid.awk $VBI > freemix.tsv

    CMD=(
        /home/dnanexus/contamination_screen.py
        "$VCF_DIR"
        --outdir results
        --freemix-file freemix.tsv
        --vcf-glob "*.vcf.gz"
        --min-af "$min_af"
        --min-dp "$min_dp"
        --max-gnomad "$max_gnomad"
        --min-shared "$min_shared"
        --non-unity-count "$non_unity_count"
        --n-shared-z "$n_shared_z"
        --max-output "$max_output"
        --freemix-threshold "$freemix_threshold"
        --bin-width "$bin_width"
        --threads "$threads"
    )

    if [[ $include_non_pass == true ]]; then CMD+=(--include-non-pass); fi
    if [[ $force_refilter == true ]]; then CMD+=(--force-refilter); fi
    if [[ $plots == true ]]; then CMD+=(--plots); fi
    if [[ $verbose == true ]]; then CMD+=(--verbose); fi
    if [[ -e $SAMPLESHEET ]]; then CMD+=(--plate-layout plate_layout.tsv); fi

    python3 "${CMD[@]}"

    mkdir -p out/matrix out/summary out/filtered_vcfs out/filtered_vcf_indexes out/filter_jsons
    mv results/matrix.tsv out/matrix/
    mv results/summary.tsv out/summary/
    mv results/filtered/*.vcf.gz out/filtered_vcfs/
    mv results/filtered/*.vcf.gz.tbi out/filtered_vcf_indexes/
    mv results/filtered/*.json out/filter_jsons
    mv results/* out/

    dx-upload-all-outputs
}
