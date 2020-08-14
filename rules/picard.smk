"""
This rule creates a sequence dictionary from a fasta file with Picard
More information at: https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/picard/createsequencedictionary.html
"""
rule picard_createsequencedictionary:
    input:
        refs_pack_dict["fasta"]
    output:
        refs_pack_dict["fasta_dictionary"]
    message:
        "Building sequence dictionary for reference genome sequence"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    params:
        extra = config["params"].get(
            "picard_create_sequence_dictionary_extra",
            ""
        )
    log:
        "logs/picard_createsequencedictionary.log"
    wrapper:
        f"{swv}/bio/picard/createsequencedictionary"


"""
This rule collects insert size metrics required by pindel.
Mire information at:
https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/picard/collectinsertsizemetrics.html
"""
rule picard_collectinsertsizemetrics:
    input:
        "bam/{sample}.bam"
    output:
        txt="picard/stats/{sample}.isize.txt",
        pdf="picard/stats/{sample}.isize.pdf"
    message:
        "Gathering insert size metrics from {wildcards.sample}"
    threads:
        1
    resources:
        mem_mb = (
            lambda wildcards, attempt: min(attempt * 2048, 10240)
        ),
        time_min = (
            lambda wildcards, attempt: min(attempt * 20, 200)
        )
    params:
        "VALIDATION_STRINGENCY=LENIENT "
        "METRIC_ACCUMULATION_LEVEL=null "
        "METRIC_ACCUMULATION_LEVEL=SAMPLE"
    log:
        "logs/picards/collectinsertsizemetrics/{sample}.log"
    wrapper:
        f"{git}/bio/picard/collectinsertsizemetrics"
