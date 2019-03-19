#! /bin/bash
#$ -N homer
#$ -pe openmp 1
#$ -q abio128
#$ -R y
#$ -ckpt restart
#$ -t 1


# ----------------------------------------------------------------------------
# Call peaks
# ----------------------------------------------------------------------------
module load homer/4.7

findPeaks /share/samdata/yhliang/19advinformatics/wk6to10/Finalproject/H37/homer-tags -LP .1 -poisson .1 -style factor -size 150 -minDist 50 -localSize 50000 -o H37_150bp.peaks.txt

findPeaks /share/samdata/yhliang/19advinformatics/wk6to10/Finalproject/H38/homer-tags -LP .1 -poisson .1 -style factor -size 150 -minDist 50 -localSize 50000 -o H38_150bp.peaks.txt

findPeaks /share/samdata/yhliang/19advinformatics/wk6to10/Finalproject/H39/homer-tags -LP .1 -poisson .1 -style factor -size 150 -minDist 50 -localSize 50000 -o H39_150bp.peaks.txt



