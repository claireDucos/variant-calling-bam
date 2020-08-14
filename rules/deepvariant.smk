"""
This rule performs deepvariant calling
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/deepvariant.html
"""
rule deepvariant:
    input:
        bam="bam/{sample}.bam",
        bam_index="bam/{sample}.bam.bai",
        ref=refs_pack_dict["fasta"],
        ref_index=refs_pack_dict["fasta_index"],
        ref_dictionary=refs_pack_dict["fasta_dictionary"]
    output:
        vcf="deepvariant/{sample}.vcf.gz"
    message:
        "Calling variants on {wildcards.sample} with DeepVariant"
    params:
        model="wes",
        extra=config["params"].get("deepvariant_extra", "")
    threads:
        min(20, max(2, config["threads"]))
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    log:
        "logs/deepvariant/call/{sample}.log"
    wrapper:
        f"{git}/bio/deepvariant"


"""
This rule indexes deepvariant VCF files for downstream analyses
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/tabix.html
"""
rule deepvariant_tabix:
    input:
        "deepvariant/{sample}.vcf.gz"
    output:
        "deepvariant/{sample}.vcf.gz.tbi"
    message:
        "Indexing deepvariant's calls for {wildcards.sample}"
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
        "-p vcf"
    log:
        "logs/deepvariant/index/{sample}.log"
    wrapper:
        f"{git}/bio/tabix"
