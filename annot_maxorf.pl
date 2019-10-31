#!/usr/bin/perl -w
=pod
add longest(also with matched domain from couple of databases) ORF region predicted by interproscan to a existed GTF file;
input: annotation.txt,gtf
output: gtf with CDS feature
=cut
 
use warnings;
my($gtf,$annotation,$output)=@ARGV;
open GTF, "$gtf" or die "!";
open ANT, "$annotation" or die "!";
open OUT, ">$output" or die "Can not open file $output!";

# read orf start and end from annotation file
my %orfs;
while (<ANT>){
  my @line=split /\s+/;
  my $id=$line[0];
  $orfs{$id}=[$line[3],$line[4]] if  ! $orfs{$id};
}
 
# define function to get nucleotide length and number of exons

# push all exons to a hash
while (<GTF>){
  next if /^#/;
  s/\s+$//;
  my @t=split/\t/;
  my ($id) = $t[8]=~ /transcript_id "([^"]+)"/; # ?
  #print $id;
  if ($t[2] eq "exon"){
    push @{$exons{$id}},\@t;
  }
  if ($t[2] eq "transcript"){
    $trans{$id}=\@t;
	}
}

for $id (sort keys %exons){ ## Schwartzian sorting :combine sort and map,from down to up; after sorting, exons 
                             ##    are ordered from smallest to largest  
  my @ordered_exon = ( map { $_->[1] }
					sort { $a->[0] <=> $b->[0]}
					map { [$_->[3] , $_] } # return anonymous array : start position and @{$exons{$id}}
					@{$exons{$id}} );
  my $i=1;
  my $number=scalar @ordered_exon;
  my @len;  
  my @ordered_out;
  my ($fCDS,$lCDS);
 
  for my $exon(@ordered_exon){
    push @ordered_out,$exon;
    if (defined $orfs{$id}) {
       my ($start,$end) =($orfs{$id}->[0],$orfs{$id}->[1]);	 
       if($i == 1){
	    $len[0]=0;
	    $len[$i]=$exon->[4]-$exon->[3]+1 ;
	    }
        else {
	   $len[$i]=$len[$i-1]+$exon->[4]-$exon->[3]+1;
	    }
	   # decide which exons are CDSs
	    if ( $len[$i] >= $start  && $len[$i-1] < $start && $len[$i] < $end){
	        $fCDS=[$exon->[0],$exon->[1],"CDS",
		            $exon->[3]+$start-$len[$i-1]-1,
					$exon->[4],$exon->[5],$exon->[6],
					$exon->[7],$exon->[8],
					];
		  push @ordered_out,$fCDS;
	    }
		elsif ($len[$i] >= $end  && $len[$i-1] < $end && $len[$i-1] > $start){
		   $lCDS=[$exon->[0],$exon->[1],"CDS",
		            $exon->[3],
					$exon->[3]+$end-$len[$i-1]-1,
					$exon->[5],$exon->[6],
					$exon->[7],$exon->[8],
					];
		  push @ordered_out,$lCDS;	  
		}
        elsif ( $len[$i-1] > $start && $len[$i] < $end ){
		   $mCDS=[$exon->[0],$exon->[1],"CDS",
		            $exon->[3],
					$exon->[4],$exon->[5],$exon->[6],
					$exon->[7],$exon->[8],
					];
		  push @ordered_out,$mCDS;
		}
		elsif ( $len[$i-1] < $start &&  $len[$i] > $end ){ # $len[$i-1]<$start<$end<$len[$i]
		$fCDS=$lCDS=[$exon->[0],$exon->[1],"CDS",
		             $exon->[3]+$start-$len[$i-1]-1,
					 $exon->[3]+$end-$len[$i-1]-1,
					 $exon->[5],$exon->[6],
					 $exon->[7],$exon->[8],
		            ];
		  push @ordered_out,$fCDS;
		}
        
	}
	$i++;
  }
  #add stop_codon and start_codon;
  #start codon falls within CDS; while stop codon falls outside of CDS;
  if ($trans{$id}->[6] eq "+" && defined $fCDS && defined $lCDS){
    my $start_codon=[$fCDS->[0],$fCDS->[1],"start_codon",
	                 $fCDS->[3],$fCDS->[3]+2,
                     $fCDS->[5],$fCDS->[6],
                     $fCDS->[7],$fCDS->[8],
                    ];
    my $stop_codon= [$lCDS->[0],$lCDS->[1],"stop_codon",
	                 $lCDS->[4]+1,$lCDS->[4]+3,
                     $lCDS->[5],$lCDS->[6],
                     $lCDS->[7],$lCDS->[8],
                    ];
	push @ordered_out,$start_codon;
	push @ordered_out,$stop_codon;
  }
  elsif ($trans{$id}->[6] eq "-" && defined $fCDS && defined $lCDS){
    my $start_codon=[$lCDS->[0],$lCDS->[1],"start_codon",
	                 $lCDS->[4]-2,$lCDS->[4],
                     $lCDS->[5],$lCDS->[6],
                     $lCDS->[7],$lCDS->[8],
                    ];
    my $stop_codon= [$fCDS->[0],$fCDS->[1],"stop_codon",
	                 $fCDS->[3]-3,$fCDS->[3]-1,
                     $fCDS->[5],$fCDS->[6],
                     $fCDS->[7],$fCDS->[8],
                    ];
	push @ordered_out,$start_codon;
	push @ordered_out,$stop_codon;					
  }

	    		
  print OUT join("\t",@{$trans{$id}}),"\n";
  for my $exons(@ordered_out){
    print OUT join("\t",@$exons),"\n";
	}
}

close ANT;
close GTF;
close OUT;
	




