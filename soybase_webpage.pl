#!/usr/bin/perl
use strict;
use warnings;
use LWP 5.64;               ##载入新版本的LWP classes
use LWP::Simple;
use LWP::UserAgent;
use LWP::ConnCache;
use HTML::TreeBuilder;
use Encode;
 
open LOGFH,">>log" || die "Open log file faild:$!.";              ##记录程序运行过程中的失败或成功信息
open DATAFH,">>data" || die "open data file failed:$!";               ##从网页上把图书信息抽取出来后存入data文件
 
my @urls=();                                                        ##根据初始URL和页面间的链接关系建立要搜寻的目标URL群体
my $starturl="http://www.soybase.org/search/qtllist_by_symbol.php";
push @urls,$starturl;
 
my $browser=LWP::UserAgent->new();                                   ##LWP::UserAgent用来请求页面
$browser->agent('Mozilla/4.0 (compatible; MSIE 5.12; Mac_PowerPC)');##伪装一下
$browser->timeout(10);                                               ##request连接超时为10秒
$browser->protocols_allowed(['http','gopher']);                      ##只接受 http 和 gopher 协议
$browser->conn_cache(LWP::ConnCache->new());
 
my $url=shift @urls;
my $response=$browser->get($url);
unless ($response->is_success){
  print LOGFH "无法获取$url -- ",$response->status_line,"\n";
}    
my $html=$response->content;
if(scalar @urls<1000000){                                            ##控制@urls的容量，避免内存溢出
  while($html=~m/href=\'(.*?)\'/ig){                          ##本页面上的所有链接都加入目标搜索范围
      my $response2=$browser->get($1);
      unless ($response2->is_success){
      print LOGFH "无法获取$url -- ",$response2->status_line,"\n";
      } 
      my $html2=$response2->content;
      if(scalar @urls<1000000){                                            ##控制@urls的容量，避免内存溢出
        while($html2=~m/href=\'(.*?)\'/ig){
          push @urls,URI->new_abs($1,$response2->base);
          print LOGFH "$1\n";
        }
      }
  }
}
    
while(scalar @urls>0){
    my $url=shift @urls;
    unless ($url=~/category\=QTLName\&search_term/){
    	print LOGFH "$url不是这个网站页面.\n";
      next;
    }
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($url);
    my $html=$response->content;
    #unless ($response->is_success){
    #   print LOGFH "无法获取$url -- ",$response->status_line,"\n";
    #    next;
    #}
    $response->is_success or die "Failed to GET ‘$url': ",$response->status_line;
     
    $|=1;                       ##改娈输出缓存前调用一下$|=1;清空缓存                                                     
         
    select DATAFH;
    my $root=HTML::TreeBuilder->new_from_content($html);
    my $body=$root->find_by_tag_name('body');
    my $top_bar=$body->look_down('_tag','Div',
                              'class',"top_bar");
    print encode("utf-8",decode("utf-8",$top_bar->as_text())),"\n";
    my @top_bar=$body->look_down('_tag','TABLE',
                               'CELLSPACING',"1");
    foreach my $m(@top_bar){
	    my @td=$m->find_by_tag_name('TD');
	    foreach (@td){
			  print encode("utf-8",decode("utf-8",$_->as_text())),"\t";
	    }
	    print "\n";
    }
    my @tmp1=$body->look_down('_tag','TABLE',
                           'CELLSPACING',"5");
    foreach my $i(@tmp1){
#	print encode("utf-8",decode("utf-8",$i->as_text())),"=\n";
    my @tmp2=$i->look_down('_tag','TD');
    foreach (@tmp2){
       print encode("utf-8",decode("utf-8",$_->as_text())),"\t";
    }
    print "\n";
    }
    print "\n";

    $|=1;   
    $root->delete;
}
close LOGFH;
close DATAFH;