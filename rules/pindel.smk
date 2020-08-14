rule pindel_config:
    input:
        "picard/stats/{sample}.isize.txt"
    output:
        "pindel/{sample}/config.txt"
    message:
        "Building pindel configuration file for {wildcards.sample}"
    group:
        "pindel_call"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    log:
        "logs/pindel/config/{sample}.log"
    shell:
        "echo fail"


rule pindel_call:
    input:
        samples=["bam/{sample}.bam"],
        bam_index=["bam/{sample}.bam.bai"],
        ref=refs_pack_dict["fasta"],
        ref_index=refs_pack_dict["fasta_index"],
        ref_dictionary=refs_pack_dict["fasta_dictionary"]
        config="pindel/{sample}/config.txt"
    output:
        expand(
            "pindel/{sample}/all_{pindel_type}",
            pindel_type=pindel_types,
            allow_missing=True
        )
    group:
        "pindel_call"
    threads:
        min(config["threads"], 20)
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    params:
        prefix = lambda wildcards: f"pindel/{wildcards.sample}/all",
        extra = config["params"].get("pindel_call_extra", "")
    log:
        "logs/pindel/call/{sample}.log"
    wrapper:
        f"{git}bio/pindel/call"


rule pindel_to_vcf:
    input:
        ref=refs_pack_dict["fasta"],
        ref_index=refs_pack_dict["fasta_index"],
        ref_dictionary=refs_pack_dict["fasta_dictionary"],
        pindel=expand(
            "pindel/{sample}/all_{pindel_type}",
            pindel_type=pindel_types,
            allow_missing=True
        )
    output:
        "pindel/vcf/{sample}.vcf"
    message:
        "Formatting pindel call of {wildcards.sample} as VCF"
    group:
        "pindel_format"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 4096, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 40, 200)
        )
    params:
        refname=config["pindel"].get("refname", "hg38"),
        refate=config["pindel"].get("refdate", "20170110")
        extra=config["params"].get("pindel_vcf_extra", "")
    log:
        "logs/pindel/vcf/{sample}.log"
    wrapper:
        f"{git}/bio/pindel/pindel2vcf"


"""
This rule converts Pindel's raw VCF file in gzipped ones
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/bcftools/view.html
"""
rule pindel_vcf_to_vcf_gz:
    input:
        "pindel/vcf/{sample}.vcf"
    output:
        "pindel/vcf/{sample}.vcf.gz"
    message:
        "Formatting Pindel's output for {wildcards.sample}"
    group:
        "pindel_format"
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
        "logs/pindel/format/{sample}.log"
    wrapper:
        f"{git}bio/bcftools/view"



"""
This rule indexes Pindel's VCF files for downstream analyses
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/tabix.html
"""
rule pindel_tabix:
    input:
        "pindel/vcf/{sample}.vcf.gz"
    output:
        "pindel/vcf/{sample}.vcf.gz.tbi"
    message:
        "Indexing Pindel's calls for {wildcards.sample}"
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
        "pindel_format"
    params:
        "-p vcf"
    log:
        "logs/pindel/index/{sample}.log"
    wrapper:
        f"{git}/bio/tabix"
