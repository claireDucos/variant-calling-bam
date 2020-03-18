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
        "logs/varscan_pileup2indel/{sample}.log"
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
        "logs/varscan_pileup2snp/{sample}.log"
    wrapper:
        f"{swv}/bio/varscan/pileup2snp"
