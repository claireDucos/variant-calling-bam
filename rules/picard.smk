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
