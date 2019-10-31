from random import choice
data=open("degree.txt").readlines()
result=open("result.txt",'w')
dic={}
for line in data:
    line=line.strip()
    line=line.split(':')
    dic[line[0]]=int(line[1])
Copy=dic.copy()
def degree(lis,node1,node2):
        tmp=[node1,node2]
        link=','.join(tmp)
        link2=','.join([node2,node1])
        if(node1!=node2)&(lis.count(link)==0)&(lis.count(link2)==0):
            lis.append(link)
            return lis
        else:
            edge=choice(lis)
            [node3,node4]=str(edge).split(',')
            lis.remove(edge)
            degree(lis,node1,node3)
            degree(lis,node2,node4)
            return lis
i=0
lis=[]
link=0
j=0
while(j<1000):
    while(i<58374):
        a=choice(dic.keys())
        b=choice(dic.keys())
        if(a==b)&(i==0):
            continue
        elif(dic[a]==0):
            del dic[a]
        elif(dic[b]==0):
            del dic[b]
        elif(a==b)&(dic[a]==1):
            continue
        else:
            lis=degree(lis,a,b)
            i+=1
            dic[a]-=1
            dic[b]-=1
    print>>result,lis,'\n','\n'
    lis=[]
    dic=Copy.copy()
    i=0
    j+=1

