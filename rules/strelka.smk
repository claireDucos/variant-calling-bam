"""
This rule calls strelka germline on bam files
More information at: https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/strelka/germline.html
"""
rule strelka_germline:
    input:
        bam = "bam/{sample}.bam",
        genome = refs_pack_dict["fasta"],
        genome_index = refs_pack_dict["fasta_index"]
    output:
        directory("strelka/{sample}")
    message:
        "Calling large indels with Strelka on {wildcards.sample}"
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 8192, 16384)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 59, 360)
        )
    log:
        "logs/strelka/{sample}.log"
    threads:
        max(2, config["threads"])
    params:
        ref = refs_pack_dict["fasta"],
        config_extra = config["params"].get("strelka_config_extra", ""),
        run_extra=""
    wrapper:
        f"{swv}/bio/strelka/germline"
