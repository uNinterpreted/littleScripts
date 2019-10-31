# -*- coding: utf-8 -*-
import scrapy
from scrapy.http import Request
import urlparse
from ..items import SoybasespiderItem
import sys

reload(sys)
sys.setdefaultencoding("utf-8")

class SoybasespiderSpider(scrapy.Spider):
    name = 'soybasespider'
    allowed_domains = ['www.soybase.org/search/qtllist_by_symbol.php']
    start_urls = ['http://www.soybase.org/search/qtllist_by_symbol.php/']

    def parse(self, response):
        #print response.body
        #items = []
        trait_name = response.xpath("//td/a/text()").extract()   #获取首页中所有的表型名称
        for name in trait_name:  #以表型的名称为循环变量
            item = {} #构建一个空字典以收集这一级的变量
            traiturl = 'https://www.soybase.org/search/index.php?search=true&result=qtl&qtl='+name.encode('utf-8') #构建qtllist的链接
            print traiturl,name
            item['trait_name'] = name.encode('utf-8')
            #item['traiturl'] = traiturl
            #items.append(item)
            yield Request(url=traiturl,    #调用yield request访问链接并将response送到callback指定的函数
                      callback=self.parse_qtl_info_link,
                      meta={'item_1':item}, #将此级数据通过meta带到下一级
                      dont_filter = True)
    def parse_qtl_list_link(self, response):
        part = response.xpath('''//*[@id="beantable"]/tr[2]/th[3]/a/@href''').extract_first("").encode('utf-8')
        qtl_list_link = urlparse.urljoin("http://www.soybase.org",part)
        yield Request(url=qtl_list_link, #调用yield request访问链接并将response送到callback指定的函数
                      callback=self.parse_qtl_info_link,
                      meta=response.meta, #将上一级数据通过response.meta带到下一级
                      dont_filter = True
                      )
    def parse_qtl_info_link(self,response):
        #items = []
        item_1 = response.meta['item_1'] #通过item_1接收来自上一级的数据
        part = response.xpath("/html/body/div[3]/div/table/tr") #以每一个table下的行为循环变量
        #print part
        for item1 in part:
            #print item1
            item = {}
            url = item1.xpath("td[1]/a/@href").extract_first("").encode('utf-8') #解析出url，值得注意的是，table中的第一行为名称，是不能提取到链接的，所以需要加判断
            if url != None: #如果解析到的 url不是空，则进行进一步提取的操作
                qtl_name = item1.xpath("td[1]/a/text()").extract_first("").encode('utf-8')
                item['qtl_name'] = qtl_name
                LG = item1.xpath("td[2]/a/text()").extract_first("").encode('utf-8')
                item['LG'] = LG
                qtl_info_url = urlparse.urljoin("http://www.soybase.org",url)
                item['trait_name'] = item_1['trait_name']
                item['qtl_info_url'] = qtl_info_url
                yield Request(url=qtl_info_url,
                              callback=self.parse_qtl_info,
                              meta={'item_2':item},
                              dont_filter = True
                              )                
            else:
                pass
            
           
    def parse_qtl_info(self,response):
        item_2 = response.meta['item_2']
        #items = []
        item = {}
        parent1 = response.xpath("/html/body/div[3]/div/table[1]/tr[1]/td[2]/text()").extract_first("").encode('utf-8')
        parent2 = response.xpath("/html/body/div[3]/div/table[1]/tr[2]/td[2]/text()").extract_first("").encode('utf-8')
        reference = response.xpath("/html/body/div[3]/div/table/tr/td[2][@valign='top']/a/text()[1]").extract_first("").strip().encode('utf-8')
        magzine = response.xpath("/html/body/div[3]/div/table/tr/td[2][@valign='top']/a/text()[2]").extract_first("").strip().encode('utf-8')
        item['trait_name'] = item_2['trait_name']
        item['qtl_name'] = item_2['qtl_name']
        item['LG'] = item_2['LG']
        item['qtl_info_url'] = item_2['qtl_info_url']
        item['parent1'] = parent1
        item['parent2'] = parent2
        item['reference_title'] = reference
        item['reference_mag'] = magzine
        qtl_marker_link = response.xpath("/html/body/div[3]/div/table/tr/td/a[text()='See this QTL region in Sequence Browser']/@href").extract_first("").encode('utf-8')
        qtl_marker_url = urlparse.urljoin("http://www.soybase.org",qtl_marker_link)
        yield Request(url=qtl_marker_url,
                      callback=self.parse_qtl_marker,
                      meta={'item_3':item},
                      dont_filter = True
                      )
    def parse_qtl_marker(self,response):
        item = SoybasespiderItem() #实例化item
        item_3 = response.meta['item_3']
        try:
            marker3 = response.xpath("/html/body/div[3]/div/text()[3]").extract_first("").strip().encode('utf-8').replace("name:  ","")
            marker5 = response.xpath("/html/body/div[3]/div/text()[6]").extract_first("").strip().encode('utf-8').replace("name:  ","")
        except Exception,e:
            marker3 = "missing"
            marker5 = "missing"
        item['trait_name'] = item_3['trait_name']
        item['qtl_name'] = item_3['qtl_name']
        item['LG'] = item_3['LG']
        item['qtl_info_url'] = item_3['qtl_info_url']
        item['parent1'] = item_3['parent1']
        item['parent2'] = item_3['parent2']
        item['reference_title'] = item_3['reference_title']
        item['reference_mag'] = item_3['reference_mag']
        item['marker3'] = marker3
        item['marker5'] = marker5
        yield item #提交item给pipelines进行操作，比如存到数据库