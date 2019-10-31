#!/usr/bin/perl
use strict;
use warnings;
use LWP 5.64;               ##�����°汾��LWP classes
use LWP::Simple;
use LWP::UserAgent;
use LWP::ConnCache;
use HTML::TreeBuilder;
use Encode;
 
open LOGFH,">>log" || die "Open log file faild:$!.";              ##��¼�������й����е�ʧ�ܻ�ɹ���Ϣ
open DATAFH,">>data" || die "open data file failed:$!";               ##����ҳ�ϰ�ͼ����Ϣ��ȡ���������data�ļ�
 
my @urls=();                                                        ##���ݳ�ʼURL��ҳ�������ӹ�ϵ����Ҫ��Ѱ��Ŀ��URLȺ��
my $starturl="http://www.soybase.org/search/qtllist_by_symbol.php";
push @urls,$starturl;
 
my $browser=LWP::UserAgent->new();                                   ##LWP::UserAgent��������ҳ��
$browser->agent('Mozilla/4.0 (compatible; MSIE 5.12; Mac_PowerPC)');##αװһ��
$browser->timeout(10);                                               ##request���ӳ�ʱΪ10��
$browser->protocols_allowed(['http','gopher']);                      ##ֻ���� http �� gopher Э��
$browser->conn_cache(LWP::ConnCache->new());
 
my $url=shift @urls;
my $response=$browser->get($url);
unless ($response->is_success){
  print LOGFH "�޷���ȡ$url -- ",$response->status_line,"\n";
}    
my $html=$response->content;
if(scalar @urls<1000000){                                            ##����@urls�������������ڴ����
  while($html=~m/href=\'(.*?)\'/ig){                          ##��ҳ���ϵ��������Ӷ�����Ŀ��������Χ
      my $response2=$browser->get($1);
      unless ($response2->is_success){
      print LOGFH "�޷���ȡ$url -- ",$response2->status_line,"\n";
      } 
      my $html2=$response2->content;
      if(scalar @urls<1000000){                                            ##����@urls�������������ڴ����
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
    	print LOGFH "$url���������վҳ��.\n";
      next;
    }
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($url);
    my $html=$response->content;
    #unless ($response->is_success){
    #   print LOGFH "�޷���ȡ$url -- ",$response->status_line,"\n";
    #    next;
    #}
    $response->is_success or die "Failed to GET ��$url': ",$response->status_line;
     
    $|=1;                       ##����������ǰ����һ��$|=1;��ջ���                                                     
         
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