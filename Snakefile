
import snakemake.utils  # Load snakemake API
import sys              # System related operations

# Python 3.7 is required
if sys.version_info < (3, 7):
    raise SystemError("Please use Python 3.7 or later.")

# Snakemake 5.4.2 at least is required
snakemake.utils.min_version("5.11.0")

include: "rules/common.smk"
include: "rules/samtools.smk"
include: "rules/picard.smk"
include: "rules/strelka.smk"
include: "rules/varscan.smk"
include: "rules/gatk.smk"

workdir: config["workdir"]
singularity: config["singularity_docker_image"]
localrules: copy_bam, copy_extra

rule all:
    input:
        **get_vcb_targets(get_strelka=True, get_mutect2=True, get_varscan=True)
    message:
        "Finishing the Germline Variant Calling pipeline"
