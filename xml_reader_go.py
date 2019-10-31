# -*- coding: utf-8 -*-
"""
Created on Fri Apr 21 14:08:01 2017

@author: PC
"""

try: 
  import xml.etree.cElementTree as ET 
except ImportError: 
  import xml.etree.ElementTree as ET 
import sys
#import re
import os
os.chdir("E:\\5_interproscan")


#tree=ET.parse(argv[1])

tree=ET.parse("file.002_2.xml")
root=tree.getroot()

result=open("002-GO.txt",'w')
savedstdout=sys.stdout
sys.stdout=result

cor={'+':'SENSE',
     '-':"ANTISENSE"}

def maximum(orfs):
    maxlength=0
    ORF=""
    for orf in orfs:
        length=int(orf.get('end'))-int(orf.get('start'))
        if length > maxlength:
            maxlength=length
            ORF=orf
    return ORF,maxlength
            
            

for nt in root.findall("nucleotide-sequence"):
    xref=nt.find('xref')
    id=xref.get('id')
    name=xref.get('name')
    PBid=name.split(' ')[0]
    strand=name.split(' ')[1][-1]
    s1=[PBid,name.split(' ')[1]]
    orfs=[]
    for orf in nt.findall('orf'):
        if orf.find('./protein/matches/*'):
            if cor[strand] == orf.get('strand'):
                orfs.append(orf)
    (orfmax,maxlength)=maximum(orfs)
    if maxlength > 0:
        s2=[orfmax.get('strand'),orfmax.get('start'),orfmax.get('end')]                
        goid=[]
        for anot in orfmax.findall('./protein/matches/*'):               
            if anot.find('./signature/entry'):
                entry=anot.find('./signature/entry')  
                for go in entry.findall('go-xref'):
                    goid.append(go.get('id'))
        if len(goid) >= 1:
            out=s1+s2+goid
            print '\t'.join(out)
    s2=[]
    s1=[]

result.close()
sys.stdout=savedstdout





