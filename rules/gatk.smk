"""
This rule calls variants with Mutect2 from GATK
More information at: https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/gatk/mutect.html
"""
rule gatk_mutect2:
    input:
        fasta = refs_pack_dict["fasta"],
        fasta_index = refs_pack_dict["fasta_index"],
        fasta_dictionary = refs_pack_dict["fasta_dictionary"],
        map = "bam/{sample}.bam",
        map_index = "bam/{sample}.bam.bai"
    output:
        vcf = "gatk/mutect2/{sample}.vcf"
    message:
        "Calling variants with Mutect2 on {wildcards.sample}"
    threads:
        config["threads"]
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 8192, 16384)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 360)
        )
    params:
        extra = config["params"].get("gatk_mutect2_extra", "")
    log:
        "logs/gatk_mutect2/{sample}.log"
    wrapper:
        f"{swv}/bio/gatk/mutect"
