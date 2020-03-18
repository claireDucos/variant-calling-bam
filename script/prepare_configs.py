#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script prepares both design.py and config.yaml required by this pipeline
to perform variant calling on recalibrated, corrected, deduplicated, and fixed
bam-formatted files.

Usage:
python3.7 /path/to/prepare_configs.py
"""


import argparse
import logging
import pytest
import sys
import yaml

from pathlib import Path
from os.path import join
from snakemake import makedirs

# Building custom class for help formatter
class CustomFormatter(argparse.RawDescriptionHelpFormatter,
                      argparse.ArgumentDefaultsHelpFormatter):
    """
    This class is used only to allow line breaks in the documentation,
    without breaking the classic argument formatting.
    """
    pass


# Parsing command line with argparse
def parser() -> argparse.ArgumentParser:
    """
    Build the argument parser object from argparse api
    """
    main_parser = argparse.ArgumentParser(
        description=sys.modules[__name__].__doc__,
        formatter_class=CustomFormatter,
        epilog="This script does not perform magic. Please check the prepared "
               "configuration file!"
    )

    # Positional arguments
    # None

    # Optional arguments
    main_parser.add_argument(
        "--bam-dir",
        help="Path to directory containing bam files",
        default=".",
        type=str
    )

    main_parser.add_argument(
        "--previous-design",
        help="Path to previous design path, e.g. used in wes-bam-mapping-gatk",
        default=None,
        type=str
    )

    main_parser.add_argument(
        "--workdir",
        help="Path to working directory (default: %(default)s)",
        type=str,
        metavar="PATH",
        default="."
    )

    main_parser.add_argument(
        "--threads",
        help="Maximum number of threads used (default: %(default)s)",
        type=int,
        default=1
    )

    main_parser.add_argument(
        "--singularity",
        help="Docker/Singularity image (default: %(default)s)",
        type=str,
        default="docker://continuumio/miniconda3:4.4.10"
    )

    main_parser.add_argument(
        "--cold-storage",
        help="Space separated list of absolute path to "
             "cold storage mount points (default: %(default)s)",
        nargs="+",
        type=str,
        default=[" "]
    )

    # Extra parameters for command line tools
    main_parser.add_argument(
        "--copy-extra"
        help="Extra parameters for bash cp (default: %(default)s)",
        default="--verbose",
        type=str
    )

    main_parser.add_argument(
        "--picard-create-sequence-dictionary-extra"
        help="Extra parameters for Picard CreateSequenceDictionary "
             "(default: %(default)s)",
        default="",
        type=str
    )

    main_parser.add_argument(
        "--samtools-mpileup-extra"
        help="Extra parameters for samtools mpileup (default: %(default)s)",
        default="",
        type=str
    )

    main_parser.add_argument(
        "--gatk-mutect2-extra"
        help="Extra parameters for GATK Mutect2 (default: %(default)s)",
        default="",
        type=str
    )

    main_parser.add_argument(
        "--strelka-config-extra"
        help="Extra parameters for strelka configuration (default: %(default)s)",
        default="",
        type=str
    )

    main_parser.add_argument(
        "--strelka-run-extra"
        help="Extra parameters for strelka run (default: %(default)s)",
        default="",
        type=str
    )

    # Logging options
    log = main_parser.add_mutually_exclusive_group()
    log.add_argument(
        "-d", "--debug",
        help="Set logging in debug mode",
        default=False,
        action='store_true'
    )

    log.add_argument(
        "-q", "--quiet",
        help="Turn off logging behaviour",
        default=False,
        action='store_true'
    )

    return main_parser


def parse_args(args: Any) -> argparse.ArgumentParser:
    """
    This function parses command line arguments

    Parameters:
        args        Any              All command line arguments
    Return:
                    ArgumentParser   The parsed command line

    Example:
    >>> parse_args()
    """
    return parser().parse_args(args)


# Building design file
def search_bam(directory)-> Generator[Dict[str, Path], None, None]:
    """
    This function (recursively) searches for bam files. If an index is present,
    then it is joint.

    Parameters:
        directory     List[Path]    A path to search for bam files
    Return:
        List[Dict[str, Path]]   A list of ditcionnaries containing as follows:
                                {bam: /path/to/bam, bai: /path/to/bai}

    Example:
    >>> search_bam("test/bams")
    """
    for current_file in directly.iterdir():
        if current_file.is_directory():
            # Recursive search
            yield from search_bam(current_file)

        elif current_file.endswith("*.bam"):
            # Include bam index in file search
            bam = current_file
            bai = f"{str(current_file)}.bai"
            yield {
                "name": bam.stem
                "bam": bam,
                "bai": (bai if bai.exists() is True else None)
            }


def build_design(*bams: List[Dict[str, Union[Path, str, None]]],
                 previous_design: Optional[str] = None) \
                 -> pandas.DataFrame:
    """
    From a list of bam files, names and indexes, this function builds a
    pandas dataframe that will be saved

    Parameters:
        bams    List[Dict[str, Union[Path, str, None]]] A list of bam dict
        previous_design   Optional[str]     The previous design used while
                                            mapping/recalibrating/...

    Return:
        pandas.DataFrame        A DataFrame containing the whole information
                                on bam files, their bai if they exist, and
                                previous design information if provided
    """
    previous_design_path = Path(previous_design)
    previous_frame = None
    if previous_design_path.exists():
        previous_frame = pandas.read_csv(
            previous_design_path,
            sep="\t",
            dtype=str,
            header=0,
            index_col=0
        )

    design_frame = pandas.DataFrame({
        bam_dict["name"] : bam_dict
        for bam_dict in bams
    })

    try:
        design_frame = pandas.merge(
            design_frame,
            previous_frame,
            left_index=True,
            right_index=True,
            how='left'
        )
    except TypeError:
        pass

    return design_frame


# building config file
def args_to_dict(args: argparse.ArgumentParser) -> Dict[str, Any]:
    """
    Build a dictionary based on parsed command line information

    Parameters:
        args        ArgumentParser      Parsed arguments from command line

    Return:
                    Dict[str, Any]      A dictionary containing the parameters
                                        for the pipeline

    Examples:
    >>> example_options = parse_args()
    """
    config_dict = {
        "design": join(args.workdir, "design.tsv"),
        "config": join(args.workdir, "config.yaml"),
        "workdir": args.workdir,
        "threads": args.threads,
        "singularity_docker_image": args.singularity,
        "cold_storage": args.cold_storage,
        "bam_dir": args.bam_dir,
        "params": {
            "copy_extra": args.copy_extra,
            "picard_create_sequence_dictionary_extra": args.picard_create_sequence_dictionary_extra,
            "samtools_mpileup_extra": args.samtools_mpileup_extra,
            "varscan_pileup2snp_extra": args.varscan_pileup2snp_extra,
            "varscan_pileup2indel_extra": args.varscan_pileup2indel_extra,
            "gatk_mutect2_extra": args.gatk_mutect2_extra,
            
        }
    }

    logging.debug(config_dict)
    return config_dict

def main(args: argparse.ArgumentParser) -> None:
    """
    Build config, and save it, then Build design, and save it.

    Parameters:
        args    ArgumentParser      The parsed command line

    Example:
    >>> main()
    """
    logging.debug("Building output directory")
    makedirs(args.workdir)

    logging.debug("Building configuration")
    config_dict = args_to_dict(args)
    with open(config_dict["config"], "w") as config_out:
        config_out.write(yaml.dump(config_dict, default_flow_style=False))

    logging.debug("Building design")
    design_frame = build_design(
        search_bam(args.bam_dir),
        previous_design = args.previous_design
    )
    design.to_csv(
        config["design"],
        sep="\t"
    )


# Running programm is not imported
if __name__ == '__main__':
    args = parse_args(sys.argv[1:])

    try:
        main(args)
    except Exception as e:
        logging.exception("%s", e)
        sys.exit(1)

    logging.debug("Process over")
    sys.exit(0)
