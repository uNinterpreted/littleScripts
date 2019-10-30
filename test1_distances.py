#!/usr/bin/python

# Description: Search for subsets whose members share at least two mismatches in pairs.


from collections import defaultdict
from argparse import ArgumentParser
import psutil, logging, os
import numpy as np


def PreprocessFile(input_file, trim=True, bases=2):

    seq_dict = defaultdict()
    with open(input_file, "rb") as index:
        for line in index.readlines():
            seq_name, P7_index, P5_index = line.strip().split()
            length = len(P7_index) - bases if trim else len(P7_index)
            seq_dict[seq_name] = [P7_index[0:length], P5_index[0:length]]
    return seq_dict


def GetDistance(seq_dict):
    dis_dict = {}
    ids = seq_dict.keys()
    for i in range(len(ids)):
        for j in range(len(ids)):
            dis_dict[ids[i]+"-"+ids[j]] = list(map(lambda x: HammingDistance(seq_dict[ids[i]][x],
                                                                             seq_dict[ids[j]][x]), [0, 1]))
    return dis_dict


def HammingDistance(seq1, seq2):
    assert len(seq1) == len(seq2)
    return sum(s1 != s2 for s1, s2 in zip(seq1, seq2))


def MaxSubset(all_seq, dis_dict, mismatch):
    neighbor_number = {}
    for seq in all_seq:
        neighbors = {k:v for k,v in dis_dict.iteritems() if seq in k and (v[0] < mismatch or v[1] < mismatch)}
        neighbor_number[seq] = len(neighbors.keys())
    centers = max(neighbor_number.items(), key=lambda x: x[1])
    if centers[1] == 1 or len(all_seq) == 1:
        return all_seq
    all_seq = all_seq - {centers[0]}
    for pair in dis_dict.keys():
        if centers[0] in pair:
            del dis_dict[pair]
    return MaxSubset(all_seq, dis_dict, mismatch)


def retrieve(seq_dict, maxsubset, remove_list, mismatch):
    indexes = np.array([v for k, v in seq_dict.iteritems() if k in maxsubset])
    resubset = maxsubset
    for id in remove_list:
        seq = seq_dict[id]
        results = []
        for index in indexes:
            results.append(list(map(lambda x: HammingDistance(seq[x], list(index[x])),
                               [0, 1])))
        result_list = [item for i in results for item in i]
        if all(dis >= mismatch for dis in result_list):
            resubset.add(id)
    return resubset


def main(index_file, outfile, mismatch):

    index_dict = PreprocessFile(index_file)
    all_seq = set(index_dict.keys())
    dis_dict = GetDistance(index_dict)
    subset = MaxSubset(all_seq, dis_dict, mismatch)
    remove_list = all_seq - subset
    resubset = retrieve(index_dict, subset, remove_list, mismatch)

    with open(outfile, 'w') as handle:
        handle.write("Total number of members in the max subset is %s.\n"
                     % len(resubset))
        handle.writelines(str(member) + "\n" for member in resubset)


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("-in", "--input_file", dest="input_file", required=True,
                        help="Input index file.")
    parser.add_argument("-o", "--out_file", dest="out_file", required=True,
                        help="Out file to write results.")
    parser.add_argument("-m", "--mismatch", dest="mismatch", type=int, default=2,
                        help="Minimum number of mismatches between pair of sequences. "
                             "Default: 2")
    args = parser.parse_args()
    logging.basicConfig(level=logging.DEBUG, format="%(levelname)s: %(asctime)s %(message)s")
    logging.info("Program started.")
    main(args.input_file, args.out_file, args.mismatch)
    logging.info("Program ended.")
    logging.info("Memory usage: %s" % psutil.Process(os.getpid()).memory_info().rss)

