"""
This rule performs a delly variant calling on bam files
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/delly.html
"""
rule delly_call:
    input:
        samples=["bam/{sample}.bam"],
        indexes=["bam/{sample}.bam.bai"],
        ref=refs_pack_dict["fasta"],
        ref_index=refs_pack_dict["fasta_index"],
        ref_dictionary=refs_pack_dict["fasta_dictionary"]
    output:
        temp("delly/call/{sample}.bcf")
    message:
        "Calling variants on {wildcards.sample} with Delly"
    threads:
        min(20, config["threads"])
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 8192, 16384)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 360)
        )
    params:
        extra = config["params"].get("delly_extra", "")
    log:
        "logs/delly/call/{sample}.log"
    wrapper:
        f"{git}/bio/delly"


"""
This rule converts delly's BCF file in gzipped VCF ones
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/bcftools/view.html
"""
rule delly_bcf_to_vcf_gz:
    input:
        "delly/call/{sample}.bcf"
    output:
        "delly/call/{sample}.vcf.gz"
    message:
        "Formatting delly's output for {wildcards.sample}"
    group:
        "delly_format"
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
        "logs/delly/format/{sample}.log"
    wrapper:
        f"{git}bio/bcftools/view"



"""
This rule indexes delly's VCF files for downstream analyses
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/tabix.html
"""
rule delly_tabix:
    input:
        "delly/call/{sample}.vcf.gz"
    output:
        "delly/call/{sample}.vcf.gz.tbi"
    message:
        "Indexing delly's calls for {wildcards.sample}"
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
        "delly_format"
    params:
        "-p vcf"
    log:
        "logs/delly/index/{sample}.log"
    wrapper:
        f"{git}/bio/tabix"
