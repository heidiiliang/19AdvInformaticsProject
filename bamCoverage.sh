#! /bin/bash
#$ -N bam.log
#$ -pe openmp 128
#$ -q abio128
#$ -R y
#$ -ckpt restart
#$ -t 1


module load Cluster_Defaults solarese/conda3
source activate deeptools
# -----------------------------------------------------------------------------------------
# Generate bigWig file
# -----------------------------------------------------------------------------------------
bamCoverage --bam shifted_reads.bam -o signal.bigWig --binSize 30 --extendReads -of bigwig --scaleFactor 1.0 --normalizeUsing RPKM --numberOfProcessors ${NSLOTS}

bamCoverage --bam shifted_reads.bam -o H37.bigWig --binSize 30 --smoothLength 90 --extendReads -of bigwig --scaleFactor 1.48 --normalizeUsing CPM --numberOfProcessors ${NSLOTS}

