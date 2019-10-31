#!/usr/bin/python

"""
disk limit= 200Mb && memory limit= 1Mb
how to run  this program: python kmer_counting.py inputfile > outputfile
i don't know how to calculate time and space complexity.
the memory usage is about 8 Mb, 
a little higher than your requirement of 1Mb.
"""

import os
import re
import time
from sys import argv
from itertools import islice
from memory_profiler import profile

####input data and calculate nlist,nsublist
infile=open(argv[1],'r')
line=infile.readline()
(k,n,q)=line.strip().split()
nl=2*int(k)*int(n)/(200*10**6)+1
ns=int(200*(2*int(k)+32)/(0.7*2*int(k)))+1

###define dicta,dictb for seq and binary convert 
dicta={'a' : '00',
      'c' : '01',
      'g' : '10',
      't' : '11',
      }
dictb=dict(map(lambda t:(t[1],t[0]), dicta.items()))

def seq_to_binary(sequence):
    base=list(sequence)
    binary=''
    for char in base:
        binary="".join([binary,dicta[char]])
    return binary

def binary_to_sequence(binary):
    bin_list=re.findall('.{2}',binary)
    sequence=''
    for char in bin_list:
        sequence="".join([sequence,dictb[char]])
    return sequence

@profile
###jellyfish algorithm: kmer-counting and hashEntry
def kmer_counting(sublist):
    H={}
    count={}
    for kmer in sublist:
        kmer=kmer.strip()
        i=hashEntry(kmer,H)
        if i in H:
            count[i]+=1
        else:
            H[i]=kmer
            count[i]=1
    return H,count
            
def hashEntry(kmer,H):
    i=int(kmer,2)%7
    while i in H and H[i] != kmer:
        i = (i+1)%7;
    return i

####DSK algorithm and output count
for i in range(0,nl): 
    for line in islice(infile,0,None):
        kmer=line.strip()
        if kmer != '' and kmer.find('n') < 0:
            if int(seq_to_binary(kmer),2)%nl == i:
                j=(int(seq_to_binary(kmer),2)/nl)%ns
                f=open('tempfile'+str(i)+str(j)+'.txt','a+') 
                f.write(seq_to_binary(kmer)+'\n')
                f.close()
    for j in range (0,ns):
        if os.path.exists('tempfile'+str(i)+str(j)+'.txt'):
            temp=open('tempfile'+str(i)+str(j)+'.txt','r')
            sublist=temp.readlines()            
            (H,count)=kmer_counting(sublist)
            for char in H:
                if count[char] >= int(q):
                    print str(count[char])+' '+binary_to_sequence(H[char])
            temp.close()
            os.remove('tempfile'+str(i)+str(j)+'.txt')
print time.clock()           
infile.close()