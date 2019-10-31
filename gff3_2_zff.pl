#!/usr/bin/perl -w

# convert gff3 file into zff file as required.
# perl gff3_2_zff.pl  R1_R2.collapsed.gff3 R1_R2.collapsed.zff


use warnings;
my($input,$output)=@ARGV;
open IN, "$input" or die "Cannot open $input !";
open OUT,">$output" or die "Cannot open and write $output !";

# push all exons to a hash
while (<IN>){
   next if /^#/;
   s/\s+$//;
   my @t=split/\t/;
   $t[8]= ~ /[Name|Parent]=(PB\.\d+)/ ;
   my $id=$1 ;
   if ($t[2] eq "exon"){
       push @{$exons{$id}},\@t;
   }
   if ($t[2] eq "gene" ){
       $trans{$id}=\@t;
   }
}

for $id (
    sort { $trans{$a}->[0] eq $trans{$b}->[0] ?
           $trans{$a}->[3] <=> $trans{$b}->[3] :
           $trans{$a}->[0] cmp $trans{$b}->[0]
            } keys %exons
        ){
    my @ordered_exons=(
        map{$_->[2]}
        sort{ $a->[0] eq  $b->[0] ? $a->[1] <=> $b->[1] : $a->[0] <=> $b->[0] }
        map{[$_->[3] ,$_->[4] ,$_]}
        @{$exons{$id}}
    );

    my $i=1;
    my $number=scalar @ordered_exons;
    my @output;

    for my $exon (@ordered_exons){

        my $label;
        if($number == 1){
            $label="Esngl";
        }elsif($number == $i ){
            $label="Eterm";
        }elsif($i == 1){
            $label="Einit";
        }else{
            $label="Exon";
        }

        if($exon->[6] eq "+") {
            $zff_exon=[$label,$exon->[3]-$trans{$id}->[3]+1,
                       $exon->[4]-$trans{$id}->[3]+1,$id
            ];
        }
        else {
            $zff_exon=[$label,$trans{$id}->[4]-$exon->[3]+1,
                       $trans{$id}->[4]-$exon->[4]+1,$id
            ];
        }
        push @output,$zff_exon;
        $i++;
    }
    print OUT ">",$id,"\n";
    for my $out(@output){
        print OUT join("\t",@$out),"\n";
    }
}

close IN;
close OUT;

