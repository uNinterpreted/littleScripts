#-*- coding:utf-8 -*-
import urllib2,urllib,httplib
import json
import socket 
 
class xBaiduMap:
    def __init__(self,key='PiDtmGoVcXLXotM24HDothpQ9HS07NCH'):
        self.host='http://api.map.baidu.com'
        self.path='/geocoder/v2/?'
        self.param={'address':None,'output':'json','ak':key,'location':None,'city':None}
        self.header={'User-Agent' : 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT)'}
       
    def getLocation(self,address,city=None):
        rlt=self.geocoding('address',address,city)
        if rlt!=None:
            l=rlt['result']
            if isinstance(l,list):
                return None
            return l['location']['lat'],l['location']['lng']
         
    def getAddress(self,lat,lng):
        rlt=self.geocoding('location',"{0},{1}".format(lat,lng))
        if rlt!=None:
            l=rlt['result']
            return l['formatted_address']
			
    def geocoding(self,key,value,city=None):
        if key=='location':
            if 'city' in self.param:
                del self.param['city']
            if 'address' in self.param:
                del self.param['address']
             
        elif key=='address':
            if 'location' in self.param:
                del self.param['location']
            if city==None and 'city' in self.param:
                del self.param['city']
            else:
                self.param['city']=city
        self.param[key]=value
	req = urllib2.Request(self.host+self.path, urllib.urlencode(self.param), self.header )
	while True:
		try:
			r=urllib2.urlopen(req, timeout = 20)
			rlt=json.loads(r.read())
		except urllib2.URLError, e:
			pass
		else:
			break
        if rlt['status']== 0:
            return rlt
        else:
            print "Decoding Failed"
            return None

bm=xBaiduMap()
#for x in xrange(10):
#	print bm.getLocation("红旗大街淮河路",'哈尔滨')
#	print bm.getLocation("安徽阜阳市颍上县鲁口镇焦岗湖农场")
#	print bm.getLocation("人民路沙浦路",'广州')
	#print bm.getAddress(32.55831, 116.569962)
	#print bm.getAddress(36.546682, 104.171241)
