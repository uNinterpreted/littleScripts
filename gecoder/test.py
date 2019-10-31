
#!/usr/bin/python
#-*- coding:utf-8 -*-

import time
import urllib2

import gecoder


m=gecoder.xBaiduMap()

with open("result.txt") as rf:
    with open("latlng.txt","a+") as wf:
        results = []
        for num,line in enumerate(rf.readlines(),1):
            if num%100 == 0:
#                log.info(str(num))
                if num%2000 == 0:
                    wf.writelines(results)
                    wf.flush()
                    results = []
#                    time.sleep(20*60)
#                time.sleep(15)
            time.sleep(1)
            html=m.getLocation(line.strip())
            results.append(m.getLocation(line.strip()))
            print html 
        #wf.writelines(results)
           


#with open("result.txt",'rt') as f:
#     for line in f:
#        results.append(m.getLocation(line.strip()))

#with open("latlng.txt","a+") as wf:
#      wf.writelines(results)
   
