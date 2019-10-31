#!/usr/bin/perl -w

# extract the longest transcript per locus
# 

use warnings;
use Getopt::Long;

my ($input,$output_prefix,$output_dir,$exclude_incomplete_transcripts,$help);
GetOptions(
     'input|in=s' => \$input,
	 'output_prefix|o=s' => \$output_prefix,
	 'output_dir|dir=s' => \$output_dir,
	 'exclude_incomplete_transcripts' => \$exclude_incomplete_transcripts,
	 'help|h!' => \$help,
);

my $usage="
job_B.pl:
   This program can extract the longest transcript per locus, and reserve their original features.
   Also help to exclude transcripts that missed start/stop codon or not in the complete open
   reading frame.

Usage: perl job_2.pl [options] -in input.gff3 -o output -dir /path/to/output/

Options:
       -in|--input                         Input gff3 file
       -o |--output_prefix                 Prefix of output gff3 file
       -dir|--output_dir                   Path to output dir
       --exclude_incomplete_transcripts    Whether to exclude transcripts that missed start/stop codon
	                                          or not in the complete open reading frames [Default is no].
       -h|--help                           Print this help information.

";

if ($help) {
    print $usage;
}

if(! defined $input || ! defined $output_dir|| ! defined $output_prefix ){
    print "ERROR: wrong input file or output dirs. \n";
    exit;
}

open IN, "$input" or die "Cannot open $input ";
open OUT, ">$output_dir/$output_prefix.gff3" or die "Cannot open and write $output_dir/$output_prefix.gff3 ";


my %genes;
my %trans;
my %exons;
my %gene_trans;

while (<IN>){
  next if /^#| /;
  s/\s+$//;
  my @lines=split/\t/;
  my $last_field=$lines[8];
  my $geneid='';
  my $tranid='';
  if($lines[2] eq "gene"){
    if ($last_field = ~/ID=([^;]+)/){
	  $geneid=$1;
	}
	$genes{$geneid}=\@lines;
  }
  elsif($lines[2] eq "mRNA" || $lines[2] eq "transcript"){
    if($last_field = ~/ID=([^;]+);Parent=([^;]+)/){
	  $geneid=$2;
	  $tranid=$1;
	}
	$trans{$tranid}=\@lines;
	push @{$gene_trans{$geneid}},$tranid;
	}
   else {
    if($last_field= ~/Parent=([^;]+)/){
	  $tranid= $1;
	}
	push @{$exons{$tranid}},\@lines;  # including exons, CDSs,UTRs,and start/stop codons
  }
}


for my $geneid(sort keys %genes){
  my $longest_id;
  my $longest_len=0;

  my @ordered_trans = @{$gene_trans{$geneid}};

  for my $tranid(@ordered_trans){
     @exons= grep {$_->[2] eq "exon" } @{$exons{$tranid}};
     my $tran_len=0;
	 for $e(@exons){
	    my $tran_len+=$e->[4]-$e->[3]+1;
	 }
    if($tran_len >= $longest_len){
	    $longest_len=$tran_len;
		$longest_id=$tranid;
	}
  }

  if($exclude_incomplete_transcripts &&  &check_completeness(@{$exons{$longest_id}}) !=1  ){
    print "Transcript $longest_id is incomplete. Ignored. \n";
    next;
  }
  else {
    print OUT join("\t",@{$genes{$geneid}}),"\n";
	print OUT join("\t",@{$trans{$longest_id}}),"\n";
	for my $exons_output(@{$exons{$longest_id}}){
	  print OUT join("\t",@$exons_output),"\n";
	}
  }

}

sub check_completeness{
     my @cds = grep {$_->[2] eq "CDS"} @_;
	 my $cds_len=0;
	 my $start_codon = grep {$_->[2] eq "start_codon"} @_;
	 my $stop_codon = grep {$_->[2] eq "stop_codon"} @_;

	 for $c(@cds){
	   $cds_len +=$c->[4]-$c->[3]+1;
	 }
     if ( $start_codon  &&  $stop_codon && $cds_len > 0 && ($cds_len % 3 )==0){
       return 1;
     }
     else{
       return 0;
     }
}








