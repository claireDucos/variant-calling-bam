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
        vcf = temp("gatk/mutect2/{sample}.vcf")
    message:
        "Calling variants with Mutect2 on {wildcards.sample}"
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
        extra = config["params"].get("gatk_mutect2_extra", "")
    log:
        "logs/gatk/mutect2/call/{sample}.log"
    wrapper:
        f"{swv}/bio/gatk/mutect"


"""
This rule converts Mutect2's raw VCF file in gzipped ones
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/bcftools/view.html
"""
rule mutect2_vcf_to_vcf_gz:
    input:
        "gatk/mutect2/{sample}.vcf"
    output:
        "gatk/mutect2/{sample}.vcf.gz"
    message:
        "Formatting Mutect2's output for {wildcards.sample}"
    group:
        "mutect2_format"
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
        "logs/gatk/mutect2/format/{sample}.log"
    wrapper:
        f"{git}bio/bcftools/view"



"""
This rule indexes Mutect2's VCF files for downstream analyses
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/tabix.html
"""
rule mutect2_tabix:
    input:
        "gatk/mutect2/{sample}.vcf.gz"
    output:
        "gatk/mutect2/{sample}.vcf.gz.tbi"
    message:
        "Indexing Mutect2's calls for {wildcards.sample}"
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
        "mutect2_format"
    params:
        "-p vcf"
    log:
        "logs/gatk/mutect2/index/{sample}.log"
    wrapper:
        f"{git}/bio/tabix"


"""
This rule calls variant with Haplotype Caller from GATK
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/gatk/haplotypecaller.html
"""
rule gatk_haplotypecaller:
    input:
        ref = refs_pack_dict["fasta"],
        ref_index = refs_pack_dict["fasta_index"],
        ref_dictionary = refs_pack_dict["fasta_dictionary"],
        bam = "bam/{sample}.bam",
        bam_index = "bam/{sample}.bam.bai"
    output:
        gvcf = "gatk/haplotypecaller/{sample}.g.vcf"
    message:
        "Calling variants with Haplotype Caller on {wildcards.sample}"
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
        extra = config["params"].get("gatk_mutect2_extra", ""),
        java_opt = (
            lambda wildcards, attempt: f"-Xmx={min(attempt * 8192, 16384)}M"
        )
    log:
        "logs/gatk/haplotypecaller/{sample}.log"
    wrapper:
        f"{swv}/bio/gatk/haplotypecaller"


"""
This rule converts haplotypecaller's raw VCF file in gzipped ones
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/bcftools/view.html
"""
rule haplotypecaller_vcf_to_vcf_gz:
    input:
        "gatk/haplotypecaller/{sample}.g.vcf"
    output:
        "gatk/haplotypecaller/{sample}.g.vcf.gz"
    message:
        "Formatting Haplotype Caller's output for {wildcards.sample}"
    group:
        "haplotypecaller_format"
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
        "logs/gatk/haplotypecaller/format/{sample}.log"
    wrapper:
        f"{git}bio/bcftools/view"



"""
This rule indexes Haplotype Caller's VCF files for downstream analyses
More information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/bio/tabix.html
"""
rule haplotypecaller_tabix:
    input:
        "gatk/haplotypecaller/{sample}.g.vcf.gz"
    output:
        "gatk/haplotypecaller/{sample}.g.vcf.gz.tbi"
    message:
        "Indexing Haplotype Caller's calls for {wildcards.sample}"
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
        "haplotypecaller_format"
    params:
        "-p vcf"
    log:
        "logs/gatk/haplotypecaller/index/{sample}.log"
    wrapper:
        f"{git}/bio/tabix"
