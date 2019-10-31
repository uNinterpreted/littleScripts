#!/usr/bin/python

"""
extract dn,ds from paml results 

how to run this program:
python job_a.py --input PAML.yn00.all --out_dir ./result/
or
python job_a.py --input PAML.yn00.all --out_dir ./result/ --min_dn 0.2 --min_ds 0.2
"""

import os,sys
import re


def main(args):
    if not os.path.exists(args.out_dir):
	    os.makedirs(args.out_dir)

    infile=open(args.input,'r')
    out_nj=open(args.out_dir+'Nei-Gojobori','w')
    out_nj.write("ID1:ID2"+"\t"+"Dn"+"\t"+"Ds"+"\t"+"Dn/Ds"+"\n")

    out_yn=open(args.out_dir+'Yang_Nielsen','w')
    out_yn.write("ID1:ID2"+"\t"+"Dn"+"\t"+"Ds"+"\t"+"Dn/Ds"+"\n")

    out_pb=open(args.out_dir+'LPB93','w')
    out_pb.write("ID1:ID2"+"\t"+"Dn"+"\t"+"Ds"+"\t"+"Dn/Ds"+"\n")

    out_lw=open(args.out_dir+'LWL85','w')
    out_lw.write("ID1:ID2"+"\t"+"Dn"+"\t"+"Ds"+"\t"+"Dn/Ds"+"\n")

    out_lm=open(args.out_dir+'LWLm','w')
    out_lm.write("ID1:ID2"+"\t"+"Dn"+"\t"+"Ds"+"\t"+"Dn/Ds"+"\n")

    entries=infile.read().split("YN")
    for entry in entries:
	    extract_dn_ds(entry,args.min_dn,args.min_ds,out_nj,out_yn,out_pb,out_lw,out_lm)

    infile.close()
    out_nj.close()
    out_yn.close()
    out_lw.close()
    out_lm.close()
    out_pb.close()

def extract_dn_ds(entry,min_dn,min_ds,out_nj,out_yn,out_pb,out_lw,out_lm):
    if len(entry.split("\n")) == 112:
        lines=entry.split("\n")

        pat_a=re.compile("\s+")
        pat_b=re.compile("[^\d\.\-naninf]+")

        id=pat_a.split(lines[78])[0]+":"+pat_a.split(lines[79])[0]
        nj=pat_b.split(lines[79]) #  2:3:4 dn/ds dn ds
        yn=pat_a.split(lines[90]) # 7:8:11 dn/ds dn ds
        lw=pat_b.split(lines[107]) # 2:3:4 ds dn dn/ds
        lm=pat_b.split(lines[108])
        pb=pat_b.split(lines[109])

        if float(nj[3]) >=  min_dn and float(nj[4]) >= min_ds:
            out_nj.write(id+"\t"+nj[3]+"\t"+nj[4]+"\t"+nj[2]+"\n")
        if float(yn[8]) >=  min_dn and float(yn[11]) >= min_ds:
            out_yn.write(id+"\t"+yn[8]+"\t"+yn[11]+"\t"+yn[7]+"\n")
        if float(lw[3]) >=  min_dn and float(lw[2]) >= min_ds:
            out_lw.write(id+"\t"+lw[3]+"\t"+lw[2]+"\t"+lw[4]+"\n")
        if float(lm[3]) >=  min_dn and float(lm[2]) >= min_ds:
            out_lm.write(id+"\t"+lm[3]+"\t"+lm[2]+"\t"+lm[4]+"\n")
        if float(pb[3]) >=  min_dn and float(pb[2]) >= min_ds:
            out_pb.write(id+"\t"+pb[3]+"\t"+pb[2]+"\t"+pb[4]+"\n")
	else:
	    pass


from argparse import ArgumentParser

parser=ArgumentParser()
parser.add_argument("--input","-in",help="Input file from paml results",required=True)
parser.add_argument("--out_dir","-out",help="Output dir of results")
parser.add_argument("--min_dn",default=0,type=float,help="Minimal value of Dn to output (default is 0)")
parser.add_argument("--min_ds",default=0,type=float,help="Minimal value of Ds to output (default is 0)")

args=parser.parse_args()

main(args)




