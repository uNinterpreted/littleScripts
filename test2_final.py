#!/usr/bin/python

# Description: demultiplex fq files with index, allowing for mismatches
# Update: 2019-07-17 / transfer distance calculation to alternative index in a dict

from Bio import SeqIO
from argparse import ArgumentParser
from collections import defaultdict
from os.path import basename
from jit_open import Handle, Queue
import gzip, os.path, subprocess
import logging
import numpy as np


def read_index(index_file, input_fq, outdir, queue):

    handles = defaultdict()
    with open(index_file, "rb") as index_handle:
        for line in index_handle:
            sample_name, index1, index2 = line.strip().split(",")
            index = "+".join([index1, index2])
            handles[index] = Handle("{}/{}_{}".format(outdir, sample_name,
                                                      basename(input_fq)).replace(".gz", ""), queue)
    handles["Undetermined"] = Handle("{}/Undetermined_{}".format(outdir, 
                                                                 basename(input_fq)).replace(".gz", ""), queue)
    return handles


def _get_index(record_index, alt_index):
    index_pair = record_index.split("+")
    alt_index_P5, alt_index_P7 = alt_index
    for key in alt_index_P5.keys():
        if index_pair[0] in alt_index_P5[key] and index_pair[1] in alt_index_P7[key]:
                return key
    return False


def BaseRepace(indexes):
    indexes.remove("Undetermined")
    sample_pairs = np.array([index.split("+") for index in indexes])
    alter = ["A", "C", "G", "T", "N"]
    alt_index_P5, alt_index_P7= defaultdict(list), defaultdict(list)
    for item in sample_pairs:
        items = "+".join(item)
        for _i, base in enumerate(item[0]):
            alt_index_P5[items] += [item[0][:_i] + alt + item[0][_i+1:] for alt in alter]
            alt_index_P7[items] += [item[1][:_i] + alt + item[1][_i + 1:] for alt in alter]
    return [alt_index_P5, alt_index_P7]


def write_results(out_handle, record, file_format):

    SeqIO.write(record, out_handle, file_format)


def main(input_files, index_file, outdir):

    queue = Queue()
    fq_readers = list(map(lambda x: SeqIO.parse(gzip.open(x, "rb"), "fastq"),
                          input_files))
    index_handles = list(map(lambda x: read_index(index_file, x, outdir, queue),
                             input_files))
    alter_index = BaseRepace(index_handles[0].keys())
    for records, indexes in zip(fq_readers, index_handles):
        while True:
            try:
                record = next(records)
                sample_index = _get_index(record.description.split(":")[-1], alter_index)
                if sample_index:
                    write_results(indexes[sample_index], record, "fastq")
                else:
                    write_results(indexes["Undetermined"], record, "fastq")
            except StopIteration:
                break


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("-fq", "--fastq_files", dest="inputFq", required=True,
                        help="Input fastq files, separate by comma.")
    parser.add_argument("-i", "--index", dest="index", required=True,
                        help="Index file.")
    parser.add_argument("-o", "--outdir", dest="outdir", required=True,
                        help="Output directory.")
    args = parser.parse_args()
    
    logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(asctime)s %(message)s")
    logging.info("Program started.")
    if not os.path.exists(args.outdir):
        subprocess.check_call("mkdir -p %s" % args.outdir, shell=True)

    fq_files = args.inputFq.split(",")
    if len(fq_files) >= 1:
        main(fq_files, args.index, args.outdir)
    logging.info("Program ended.")
