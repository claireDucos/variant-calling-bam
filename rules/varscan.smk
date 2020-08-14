"""
This rule calls indel with Varscan
"""
rule varscan_pileup2indel:
    input:
        "samtools/mpileup/{sample}.mpileup.gz"
    output:
        "varscan/indel/{sample}.vcf.gz"
    message:
        "Calling indel with Varscan on {wildcards.sample}"
    threads:
        3
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    params:
        extra = config["params"].get("varscan_pileup2indel", "--output-vcf 1")
    log:
        "logs/varscan/pileup2indel/call/{sample}.log"
    wrapper:
        f"{swv}/bio/varscan/pileup2indel"


"""
This rule calls snp with Varscan
"""
rule varscan_pileup2snp:
    input:
        "samtools/mpileup/{sample}.mpileup.gz"
    output:
        "varscan/snp/{sample}.vcf.gz"
    message:
        "Calling SNP with Varscan on {wildcards.sample}"
    threads:
        3
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    params:
        extra = config["params"].get("varscan_pileup2snp", "--output-vcf 1")
    log:
        "logs/varscan/pileup2snp/call/{sample}.log"
    wrapper:
        f"{swv}/bio/varscan/pileup2snp"


"""
This rule indexes Varscan2's VCF files for downstream analyses
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/tabix.html
"""
rule pindel_tabix:
    input:
        "varscan/{subcommand}/{sample}.vcf.gz"
    output:
        "varscan/{subcommand}/{sample}.vcf.gz.tbi"
    message:
        "Indexing Varscan2's calls for {wildcards.sample}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 8192, 16384)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 45, 360)
        )
    wildcard_constrains:
        subcommand = r"snp|indel"
    params:
        "-p vcf"
    log:
        "logs/varscan/{subcommand}/index/{sample}.log"
    wrapper:
        f"{git}/bio/tabix"
