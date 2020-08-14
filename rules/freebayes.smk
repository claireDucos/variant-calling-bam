"""
This rule calls variants with FreeBayes
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/freebayes.html
"""
rule freebayes:
    input:
        samples="bam/{sample}.bam",
        indexes="bam/{sample}.bam.bai",
        ref=refs_pack_dict["fasta"],
        ref_index=refs_pack_dict["fasta_index"],
        ref_dictionary=refs_pack_dict["fasta_dictionary"]
    output:
        temp("freebayes/call/{sample}.vcf")
    message:
        "Calling variants on {wildcards.sample} with FreeBayes"
    threads:
        max(2, min(20, config["threads"]))
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 8192, 16384)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 360)
        )
    params:
        extra = config["params"].get("freebayes_extra", ""),
        chunksize=100000
    log:
        "logs/freebayes/{sample}.log"
    wrapper:
        f"{git}/bio/freebayes"


"""
This rule converts Freebayes's raw VCF file in gzipped ones
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/bcftools/view.html
"""
rule freebayes_vcf_to_vcf_gz:
    input:
        "freebayes/call/{sample}.vcf"
    output:
        "freebayes/call/{sample}.vcf.gz"
    message:
        "Formatting FreeBayes's output for {wildcards.sample}"
    group:
        "freebayes_format"
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
        "logs/freebayes/format/{sample}.log"
    wrapper:
        f"{git}bio/bcftools/view"



"""
This rule indexes freebayes's VCF files for downstream analyses
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/tabix.html
"""
rule freebayes_tabix:
    input:
        "freebayes/call/{sample}.vcf.gz"
    output:
        "freebayes/call/{sample}.vcf.gz.tbi"
    message:
        "Indexing Freebayes's calls for {wildcards.sample}"
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
        "freebayes_format"
    params:
        "-p vcf"
    log:
        "logs/freebayes/index/{sample}.log"
    wrapper:
        f"{git}/bio/tabix"
