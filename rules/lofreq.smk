rule lofreq_call:
    input:
        bam="bam/{sample}.bam",
        bai="bam/{sample}.bam.bai",
        ref=refs_pack_dict["fasta"],
        ref_index=refs_pack_dict["fasta_index"],
        ref_dictionary=refs_pack_dict["fasta_dictionary"]
    output:
        temp("lofreq/{sample}.vcf")
    message:
        "Calling variants on {wildcards.sample} with LoFreq"
    threads:
        min(20, config["params"])
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    params:
        ref=refs_pack_dict["fasta"],
        extra=config["params"].get("lofreq_extra", "--verbose")
    log:
        "logs/lofreq/call/{sample}.log"
    wrapper:
        f"{git}/bio/lofreq/call"


"""
This rule converts LoFreq's raw VCF file in gzipped ones
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/bcftools/view.html
"""
rule lofreq_vcf_to_vcf_gz:
    input:
        "lofreq/{sample}.vcf"
    output:
        "lofreq/{sample}.vcf.gz"
    message:
        "Formatting LoFreq's output for {wildcards.sample}"
    group:
        "lofreq_format"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 8192, 16384)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 360)
        )
    params:
        " --output-type z "
    log:
        "logs/lofreq/format/{sample}.log"
    wrapper:
        f"{git}bio/bcftools/view"



"""
This rule indexes LoFreq's VCF files for downstream analyses
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/tabix.html
"""
rule lofreq_tabix:
    input:
        "lofreq/{sample}.vcf.gz"
    output:
        "lofreq/{sample}.vcf.gz.tbi"
    message:
        "Indexing LoFreq's calls for {wildcards.sample}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 8192, 16384)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 360)
        )
    group:
        "lofreq_format"
    params:
        "-p vcf"
    log:
        "logs/lofreq/index/{sample}.log"
    wrapper:
        f"{git}/bio/tabix"
