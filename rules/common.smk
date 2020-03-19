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


def get_vcb_targets(get_strelka: bool = False,
                    get_mutect2: bool = False) -> Dict[str, str]:
    """
    Return the list of requested output file
    """
    targets = {}
    if get_strelka is True:
        targets["strelka"] = expand(
            "strelka/{sample}",
            sample=design.Sample_id
        )

    if get_mutect2 is True:
        targets["mutect2"] = expand(
            "gatk/mutect2/{sample}.vcf",
            sample=design.Sample_id
        )

    if get_varscan is True:
        targets["varscan"] = expand(
            "varscan/{call}/{sample}.vcf.gz",
            call=["snp", "indel"],
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
