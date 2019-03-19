#! /bin/bash
#$ -N atacalignment
#$ -pe openmp 128
#$ -q abio128
#$ -R y
#$ -ckpt restart
#$ -t 1

# ----------------------------------------------------------------------------------------
# Combine Replicates reads
# ----------------------------------------------------------------------------------------
#cat tech.rep1/*_R1_* tech.rep2/*_R1_* tech.rep3/*_R1_* > read1.fastq.gz
#cat tech.rep1/*_R2_* tech.rep2/*_R2_* tech.rep3/*_R2_* > read2.fastq.gz


# -----------------------------------------------------------------------------------------
# Trim adapter sequences
# -----------------------------------------------------------------------------------------
module load java/1.8.0.111

java -jar /data/apps/trimmomatic/0.35/trimmomatic-0.35.jar \
	PE -threads ${NSLOTS} H37_S8_R1_001.fastq.gz H37_S8_R2_001.fastq.gz \
	pe_read1.fastq se_read1.fastq.gz pe_read2.fastq se_read2.fastq.gz \
	ILLUMINACLIP:/share/samdata/yhliang/genome/adapters/NexteraPE-PE.fa:2:30:8:4:true \
	LEADING:20 TRAILING:20 \
	SLIDINGWINDOW:4:17 MINLEN:30


# -----------------------------------------------------------------------------------------
# First map the reads to mitochondrial chrom only
# -----------------------------------------------------------------------------------------
module load bowtie2/2.2.7
module load samtools/1.9

bowtie2 --very-sensitive --no-discordant -X 2000 -k 10 -p ${NSLOTS} --un-conc ./unaligned.fastq -x /share/samdata/yhliang/genome/hg38/chrM/chrM -1 pe_read1.fastq -2 pe_read2.fastq | samtools view -@${NSLOTS} -Sb - > chrM.bam


# -----------------------------------------------------------------------------------------
# Next step, map unaligned reads to the human genome
# -----------------------------------------------------------------------------------------
bowtie2 --very-sensitive --no-discordant -X 2000 -k 10 -p ${NSLOTS} -x /share/samdata/yhliang/genome/hg38/hg38 -1 unaligned.1.fastq -2 unaligned.2.fastq | samtools view -@ ${NSLOTS} -Sb - > mappings.bam


# -----------------------------------------------------------------------------------------
# Remove multi-mappers (MAPQ < 255)
# -----------------------------------------------------------------------------------------
samtools view -@ ${NSLOTS} -b -q 255 mappings.bam > mappings.uniq.bam


# -----------------------------------------------------------------------------------------
# Sort the merged BAM file
# -----------------------------------------------------------------------------------------
java -jar /data/apps/picard/2.18.4/picard.jar SortSam \
	I=mappings.uniq.bam \
	O=mappings.sorted.bam \
	SORT_ORDER=coordinate


# -----------------------------------------------------------------------------------------
# Remove PCR duplicates
# -----------------------------------------------------------------------------------------
java -jar /data/apps/picard/2.18.4/picard.jar MarkDuplicates \
	I=mappings.sorted.bam \
	O=mappings.nodup.bam \
	M=duplicates_metric.txt \
	REMOVE_DUPLICATES=true


# ----------------------------------------------------------------------------------------
# Adjust the read start sites to represent the center of the transposon 
# binding event. Transposon binds as a dimer and inserts two adapters 
# separated by 9 bps. Reads aligning to the + strand are offset 
# by +4 bps, and reads aligning to the – strand are offset −5 bps.
# -----------------------------------------------------------------------------------------
samtools view -@ ${NSLOTS}  mappings.nodup.bam | python /share/samdata/yhliang/code/shift.reads.py  shifted_reads.sam

cat /share/samdata/yhliang/code/hg38_bamHeader.sam shifted_reads.sam | samtools view -@ ${NSLOTS} -Sb - > shifted_reads.bam

rm shifted_reads.sam


# -----------------------------------------------------------------------------------------
# Create Homer tag dir
# -----------------------------------------------------------------------------------------
module load homer/4.7

makeTagDirectory homer-tags shifted_reads.bam -format sam


# -----------------------------------------------------------------------------------------
# Build BAM index
# -----------------------------------------------------------------------------------------
java -jar /data/apps/picard/2.18.4/picard.jar BuildBamIndex \
	I=shifted_reads.bam
	

qsub bamCoverage.sh

#module clear
#module load Cluster_Defaults solarese/conda3
#source activate deeptools
# -----------------------------------------------------------------------------------------
# Generate bigWig file
# -----------------------------------------------------------------------------------------
#bamCoverage --bam shifted_reads.bam -o signal.bigWig --binSize 30 --extendReads -of bigwig --scaleFactor 1.0 --normalizeUsing RPKM --numberOfProcessors ${NSLOTS}
#bamCoverage --bam shifted_reads.bam -o H37.bigWig --binSize 30 --smoothLength 90 --extendReads -of bigwig --scaleFactor 1.48 --normalizeUsing CPM --numberOfProcessors ${NSLOTS}
