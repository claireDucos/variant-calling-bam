"""
This rule creates a fasta sequence index.
More information: https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/samtools/faidx.html
"""
rule samtools_faidx:
    input:
        refs_pack_dict["fasta"]
    output:
        refs_pack_dict["fasta_index"]
    message:
        "Building fasta-sequence index for reference genome sequence"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1024, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 10, 200)
        )
    log:
        "logs/samtools_faidx.log"
    wrapper:
        f"{swv}/bio/samtools/faidx"


"""
This rule builds BAM indexes on provided BAM files
"""
rule samtools_index:
    input:
        "bam/{sample}.bam"
    output:
        "bam/{sample}.bam.bai"
    message:
        "Indexing BAM file for {wildcards.sample}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1024, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    log:
        "logs/samtools_index/{sample}.log"
    wrapper:
        f"{swv}/bio/samtools/index"


"""
This rule builds a gzip-compressed pileup-formatted text file for further
variant calling operations
More information at: https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/samtools/mpileup.html
"""
rule samtools_mpileup:
    input:
        bam = "bam/{sample}.bam",
        reference_genome = refs_pack_dict["fasta"],
        reference_index = refs_pack_dict["fasta_index"]
    output:
        temp("samtools/mpileup/{sample}.mpileup.gz")
    message:
        "Building pileup file for {wildcards.sample}"
    threads:
        max(2, config["threads"])
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 1024, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    params:
        extra = config["params"].get("samtools_mpileup_extra", "")
    log:
        "logs/samtools_mpileup/{sample}.log"
    wrapper:
        f"{swv}/bio/samtools/mpileup"
