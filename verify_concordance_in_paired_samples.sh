#!/bin/sh 

# this script is used to verify concordance between paired normal and tumor samples  
# and if the concordance level is low, try to find the correct matched samples in the same batch.

usage()
{
 cat << EOF
Usage: $0 [options]
Options: [ALL OF THEM ARE REQUIRED, NO DEFAULT VAULES]
	-I|--input           The list file of dirs to paired samples. One sample dir per line. Usually the same batch.
	-O|--output          The dir to write result files, including bam files with header, pileup files, concordance files. 
	-G|--GATK            Path to the GenomeAnalysisTK.jar file [GATK 2.3 or higher, GATK 3.8 works fine].
	-P|--picard          Path to the picard.jar.
	-C|--Conpair         Path to the Conpair dir.
	-N|--python          Path to python.
	-R|--referece        The reference genome fasta file, make sure there is *.fai and *.dict file in the same directory.  
	-h|--help            Print this message. 
EOF
exit 1
}


function argparse()
{
  [ $# -eq 0 ] && usage;
  ARGS=`getopt -o I:O:G:P:C:N:R:h -l input:,output:,GATK:,picard:,Conpair:,python:,reference:,help -n 'verify_concordance_in_paired_samples.sh' -- "$@" `
  if [ $? != 0 ] ; then
  	echo "ternminating..." >&2;
  	exit 1;
  fi
  eval set -- "$ARGS";
  while true ; do
	case "$1" in 
		-I|--input) 
			if [ -f "$2" ];then 
				input="$2"
			else
				echo "ERROR: The list file provided does not exist."; exit 1
			fi
			shift 2 ;;
		-O|--output)
			if [ -d "$2" ];then
				outdir="$2"
			else
				echo "ERROR: The output dir does not exist, please mkdir $2 ." ; exit 1
			fi
			shift 2 ;;
		-G|--GATK)
			if [ -f "$2" ];then
				gatk="$2"
			else
				echo "ERROR: The GenomeAnalysisTK.jar does not exist." ; exit 1
			fi
			shift 2 ;;
		-P|--picard)
			if [ -f "$2" ];then
				picard="$2"
			else
				echo "ERROR: The picard.jar does not exist." ;exit 1
			fi
			shift 2 ;;
		-C|--Conpair)
			if [ -d "$2" ];then
				conpair="$2"
			else
				echo "ERROR: The Conpair directory does not exist." ;exit 1
			fi
			shift 2 ;;
		-N|--python)
			if [ -f "$2" ] && [ -x "$2" ];then
				python="$2"
			else
				echo "ERROR: The python path does not exist or is not executable." ;exit 1
			fi
			shift 2 ;;
		-R|--reference)
			if [ -f "$2" ];then
				ref="$2"
			else
				echo "ERROR: The reference genome fasta file does not exist." ; exit 1
			fi
			shift 2 ;;
		-h|--help)
			usage ; exit 1 ;;
		--) shift ; break ;;
		*) echo "ERROR: Wrong options"; usage ; exit 1 ;;
	esac
  done
}

function get_sample_name(){
  local bam_file
  bam_file=$(basename $1)
  local SampleName
  SampleName=${bam_file:2:9}
  echo $SampleName
}



function run_picard_pileup(){   
  local SampleName
  SampleName=`get_sample_name $1`

  java -Xmx12g -jar $picard AddOrReplaceReadGroups I=$1 O=$outdir/${SampleName}_$2.bam SORT_ORDER=coordinate RGID=${SampleName}_$2 RGLB=${SampleName}_$2 RGPL=illumina RGSM=${SampleName}_$2 RGPU=${SampleName}_$2 CREATE_INDEX=true 1>>$outdir/details.log 2>&1
  $python $conpair/scripts/run_gatk_pileup_for_sample.py  -B $outdir/${SampleName}_$2.bam -O $outdir/${SampleName}_$2.pileup  -R $ref -D $conpair -M ${marker}.bed -G $gatk 1>>$outdir/details.log 2>&1

}


argparse $@

# set the environment variables used by conpair
export GATK_JAR=$gatk
export CONPAIR_DIR=$conpair
export PYTHONPATH=$conpair/modules/

# marker file (pre-generated from b37)
marker=$conpair/data/markers/hg19.autosomes.phase3_shapeit2_mvncall_integrated.20130502.SNV.genotype.sselect_v4_MAF_0.4_LD_0.8

declare -a mysamples
declare -a failed_sample
program_start_time=`date "+%Y-%m-%d %H:%M:%S"`
cutoff=0.8

# part 1 : generated bam files with headers and pile up files

for dir in `cat $input`;do 
	filename=`find $dir -type f -name "CF*[0-9].bam"`
	if [ -n "$filename" ];then
		tumor=`echo $filename | awk '{print $1"\n"$2"\n"}'|xargs -i basename '{}'| grep C1`
		normal=`echo $filename | awk '{print $1"\n"$2"\n"}'|xargs -i basename '{}'| grep D1`
	elif [ -n "`find $dir -type f -name "BL*[0-9].bam"`" ] && [ -n "`find $dir -type f -name "[FP|FT]*[0-9].bam"`" ];then 
		tumor=`find $dir -type f -name "[FP|FT]*[0-9].bam"`
		tumor=`basename $tumor`
		normal=`find $dir -type f -name "BL*[0-9].bam"`
		normal=`basename $normal`
	else
		echo -e "ERROR: No paired bam files found in $dir . Ignored" >> $outdir/Conpair_${program_start_time}.log
		continue
	fi
	if [ -f $dir/$tumor ] && [ -f $dir/$normal ];then
		sample=`get_sample_name $dir/$tumor`
		mysamples=(${mysamples[*]} $sample)
		run_picard_pileup $dir/$tumor tumor
		run_picard_pileup $dir/$normal normal
		wait
	else 
		echo "$dir/$tumor or $dir/$normal error. Ignored" >> $outdir/Conpair_${program_start_time}.log
		continue
	fi
	time_step1=`date "+%Y-%m-%d %H:%M:%S"`
	[ $? == 0 ] && echo "[$time_step1] STEP1_PILEUP for $sample finished." >> $outdir/Conpair_${program_start_time}.log
done

# part 2 : estimate concordance level and record the samples fail to pass the threshold
for pair in ${mysamples[@]};do
	# -H flag means consider normal_homozygous_markers_only, which is recommended 
	$python $conpair/scripts/verify_concordance.py -H  -T $outdir/${pair}_tumor.pileup -N $outdir/${pair}_normal.pileup -O $outdir/${pair}_concordance.txt  -M ${marker}.txt 1>>$outdir/details.log 2>&1
	concordance=$(echo "scale=2;`cat $outdir/${pair}_concordance.txt |grep Concordance|awk '{print $2}'|tr -d %`/100"|bc)
	echo -e $pair"\t:"$concordance >> $outdir/concordance.summary
	if [ $(echo "$concordance >= $cutoff"|bc) = 1  ];then
		echo "The $pair couple passed concordance verification." >> $outdir/Conpair_${program_start_time}.log
	else
		failed_sample=(${failed_sample[*]} $pair)
		echo "Uh-oh! The $pair pairs are not matched." >> $outdir/Conpair_${program_start_time}.log
	fi
done

# part 3 : re-combine the failed samples and figure out correct matches 
[ -d $outdir/re-combine ] || mkdir $outdir/re-combine
if [ ${#failed_sample[@]} -gt 1 ];then
	for ((i=0;i<${#failed_sample[@]};i++));do
		for ((j=0;j<${#failed_sample[@]};j++));do 
		        if [ $i -ne $j ];then	
				$python $conpair/scripts/verify_concordance.py -H -T $outdir/${failed_sample[$i]}_tumor.pileup -N $outdir/${failed_sample[$j]}_normal.pileup \
					-O $outdir/re-combine/${failed_sample[$i]}_${failed_sample[$j]}_concordance.txt  -M ${marker}.txt 1>>$outdir/re-combine/details.log 2>&1
				concordance=$(echo "scale=2;`cat $outdir/re-combine/${failed_sample[$i]}_${failed_sample[$j]}_concordance.txt |grep Concordance|awk \
					'{print $2}'|tr -d %`/100"|bc)
				if [ $(echo "$concordance >= $cutoff"|bc) = 1  ];then
					echo "The ${failed_sample[$i]}_tumor and ${failed_sample[$j]}_normal seems to be a couple. \
						Their concordance level is $concordance" >> $outdir/re-combine/report.txt 
				else
					continue
				fi
			else 	
				continue
			fi
		done
	done
elif [ ${#failed_sample[@]} -eq 1 ];then
	echo "There is only one failed sample." >> $outdir/Conpair_${program_start_time}.log
else 
	echo "Congradulations! All samples are matched." >> $outdir/Conpair_${program_start_time}.log
fi
				

