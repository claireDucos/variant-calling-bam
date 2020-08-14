"""
While other .smk files contains rules and pure snakemake instructions, this
one gathers all the python instructions surch as config mappings or input
validations.
"""

import os               # OS related operations
import os.path as op    # Path and file system manipulation
import sys              # System related operations


from typing import Any, Dict, List     # Give IO information
import pandas as pd                    # Deal with TSV files (design)
from snakemake.utils import validate   # Check Yaml/TSV formats

try:
    from common_rna_count_salmon import *
except ImportError:
    print(f"Could not find common.py in {script_path}")
    print(locals())
    raise

# Snakemake-Wrappers version
swv = "https://raw.githubusercontent.com/snakemake/snakemake-wrappers/0.50.0"
# github prefix
git = "https://raw.githubusercontent.com/tdayris-perso/snakemake-wrappers"

# Loading configuration
if config == dict():
    configfile: "config.yaml"
validate(config, schema="../schemas/config.schema.yaml")

# Loading deisgn file
design = pd.read_csv(
    config["design"],
    sep="\t",
    header=0,
    index_col=None,
    dtype=str
)
design.set_index(design["Sample_id"])
validate(design, schema="../schemas/design.schema.yaml")

pindel_types = ["D", "BP", "INV", "TD", "LI", "SI", "RP"]

wildcard_constrains:
    sample = "|".join(design.Sample_id)


def get_vcb_targets(get_deepvariant: bool = False,
                    get_delly: bool = False,
                    get_freebayes: bool = False,
                    get_mutect2: bool = False,
                    get_haplotypecaller: bool = False,
                    get_lofreq: bool = False,
                    get_pindel: bool = False,
                    get_strelka: bool = False,
                    get_varscan: bool = False,) -> Dict[str, Any]:
    """
    Return the list of requested output file
    """
    targets = {}
    pipeline = config["pipeline"]
    callers = sum(1 if caller else 0 for caller in pipeline.values())

    if callers == 0:
        raise ValueError("At least one caller has to be used")

    merge_required = callers > 1

    if all(get_deepvariant, pipeline.get("run_deepvariant", True)):
        targets["deepvariant_call"] = expand(
            "deepvariant/{sample}.vcf.gz",
            sample=design.Sample_id
        )
        targets["deepvariant_idx"] = expand(
            "deepvariant/{sample}.vcf.gz.tbi",
            sample=design.Sample_id
        )

    if all(get_delly, pipeline.get("run_delly", True)):
        targets["delly_call"] = expand(
            "delly/call/{sample}.vcf.gz",
            sample=design.Sample_id
        )
        targets["delly_idx"] = expand(
            "delly/call/{sample}.vcf.gz.tbi",
            sample=design.Sample_id
        )

    if all(get_freebayes, pipeline.get("run_freebayes", True)):
        targets["freebayes_call"] = expand(
            "freebayes/call/{sample}.vcf.gz",
            sample=design.Sample_id
        )
        targets["freebayes_idx"] = expand(
            "freebayes/call/{sample}.vcf.gz.tbi",
            sample=design.Sample_id
        )

    if all(get_mutect2, pipeline.get("run_mutect2", True)):
        targets["gatk_mutect2_call"] = expand(
            "gatk/mutect2/{sample}.vcf.gz",
            sample=design.Sample_id
        )
        targets["gatk_mutect2_idx"] = expand(
            "gatk/mutect2/{sample}.vcf.gz.tbi",
            sample=design.Sample_id
        )

    if all(get_haplotypecaller, pipeline.get("run_haplotypecaller", True)):
        targets["gatk_haplotypecaller_call"] = expand(
            "gatk/haplotypecaller/{sample}.g.vcf.gz",
            sample=design.Sample_id
        )
        targets["gatk_haplotypecaller_idx"] = expand(
            "gatk/haplotypecaller/{sample}.g.vcf.gz.tbi",
            sample=design.Sample_id
        )

    if all(get_lofreq, pipeline.get("run_lofreq", True)):
        targets["lofreq_call"] = expand(
            "lofreq/{sample}.vcf.gz",
            sample=design.Sample_id
        )
        targets["lofreq_idx"] = expand(
            "lofreq/{sample}.vcf.gz.tbi",
            sample=design.Sample_id
        )


    if all(get_pindel, pipeline.get("run_pindel", True)):
        targets["pindel_call"] = expand(
            "pindel/vcf/{sample}.vcf.gz",
            sample=design.Sample_id
        )
        targets["pindel_idx"] = expand(
            "pindel/vcf/{sample}.vcf.gz.tbi",
            sample=design.Sample_id
        )

    if all(get_varscan, pipeline.get("run_varscan", True)):
        targets["varscan_call"] = expand(
            "varscan/{subcommand}/{sample}.vcf.gz",
            subcommand=["snp", "indel"],
            sample=design.Sample_id
        )
        targets["varscan_idx"] = expand(
            "varscan/{subcommand}/{sample}.vcf.gz.tbi",
            subcommand=["snp", "indel"],
            sample=design.Sample_id
        )


    if all(get_strelka, pipeline.get("run_strelka", True)):
        targets["strelka"] = expand(
            "strelka/{sample}",
            sample=design.Sample_id
        )

    return targets


refs_pack_dict = refs_pack(config["fasta"])

try:
    bam_link_dict = bam_link(
        design.Sample_id.tolist(),
        design.Bam.tolist(),
        design.Bai.tolist()
    )
except AttributeError:
    bam_link_dict = bam_link(
        design.Sample_id.tolist(),
        design.Bam.tolist()
    )
