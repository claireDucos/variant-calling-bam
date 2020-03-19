#!/usr/bin/python3.7
# -*- coding: utf-8 -*-

"""
This script contains functions used by Snakemake. They heva bee taken aside
of the common.smk in order to be tested
"""

import pytest

from os.path import basename
from typing import Dict, List


def bam_link(sample_id: List[str], bam: List[str], bai: Optional[List[str]]) \
             -> Dict[str, str]:
    """
    Return a dictionary with:
    sample-name-.bam: bam-file-path
    """
    bam_dict = {
        f"{sample}.bam": bam
        for sample, bam in zip(sample_id, bam)
        if bam is not None
    }

    for sample, bai in zip(sample_id, bai):
        if bai is not None and f"{sample}.bam" in bam_dict.key():
            bam_dict[f"{sample}.bam.bai"] = bai

    return bam_dict


@pytest.mark.parametrize(
    "samples, bams, bai, expected", [
        (["S1"], ["/path/to/S1.bam"], None,
         {"S1.bam": "/path/to/S1.bam"}),

        (["S1", "S2", "S3"],
         ["/path/to/S1.bam", "/path/to/S2.bam", "/path/to/S3.bam"],
         None,
         {"S1.bam": "/path/to/S1.bam",
          "S2.bam": "/path/to/S2.bam",
          "S3.bam": "/path/to/S3.bam"})

        (["S1", "S2", "S3"],
         ["/path/to/S1.bam", None, "/path/to/S3.bam"],
         None,
         {"S1.bam": "/path/to/S1.bam", "S3.bam": "/path/to/S3.bam"}),

        (["S1"], ["/path/to/S1.bam"], ["/path/to/S1.bam.bai"],
         {"S1.bam": "/path/to/S1.bam", "S1.bam.bai": "/path/to/S1.bam.bai"}),

        (["S1"], None, ["/path/to/S1.bam.bai"], {}),

        (["S1"], None, None, {}),

        (["S1", "S2", "S3"],
         ["/path/to/S1.bam", None, "/path/to/S3.bam"],
         ["/path/to/S1.bam.bai", None, "/path/to/S3.bam.bai"],
         {"S1.bam": "/path/to/S1.bam",
          "S3.bam": "/path/to/S3.bam",
          "S1.bam.bai": "/path/to/S1.bam.bai",
          "S3.bam.bai": "/path/to/S3.bam.bai"}),

        (["S1", "S2", "S3"],
         ["/path/to/S1.bam", None, "/path/to/S3.bam"],
         ["/path/to/S1.bam.bai", None, None],
         {"S1.bam": "/path/to/S1.bam",
          "S3.bam": "/path/to/S3.bam",
          "S1.bam.bai": "/path/to/S1.bam.bai"}),
    ]
)
def test_bam_link(samples, bams, bai, expected) -> None:
    """
    Test bam_link function with various arguments
    """
    assert bam_link(samples, bam, bai) == expected


def refs_pack(fasta: str) -> Dict[str, str]:
    """
    Return a dictionary with:
    "fasta": fasta-path
    "fasta_index": fasta-index-path
    "fasta_dictionary": fasta-dict-path
    """
    return {
        "fasta": f"genomes/{basename(fasta)}",
        "fasta_index": f"genomes/{basename(fasta)}.fai",
        "fasta_dictionary": f"genomes/{basename(fasta)}.dict"
    }


@pytest.mark.parametrize(
    "fasta, expected", [
        ("seq.fa",
         {"fasta": "genomes/seq.fa",
          "fasta_index": "genomes/seq.fa.fai",
          "fasta_dictionary": "genomes/seq.fa.dict"}),

        ("path/to/seq.fa",
         {"fasta": "genomes/seq.fa",
          "fasta_index": "genomes/seq.fa.fai",
          "fasta_dictionary": "genomes/seq.fa.dict"}),

        ("/absolute/path/to/seq.fa",
         {"fasta": "genomes/seq.fa",
          "fasta_index": "genomes/seq.fa.fai",
          "fasta_dictionary": "genomes/seq.fa.dict"}),
    ]
)
def test_refs_pack(fasta, expected) -> None:
    """
    Test the previous refs_pack function
    """
    assert refs_pack(fasta) == expected
