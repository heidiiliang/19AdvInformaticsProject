#! /bin/bash
#$ -N t2estentire.IDR.run
#$ -pe openmp 1
#$ -q abio
#$ -R y
#$ -ckpt restart
#$ -t 1


#run program at location:150bp
#cd /share/samdata/yhliang/19advinformatics/wk6to10/Finalproject/peakcalling-idr/150bp/peaks


# ------------------------------------------------------------------------------------------------
# Create pseudoreps for individual reps (Step 5)
# ------------------------------------------------------------------------------------------------
module load python/2.4.6 
mkdir -p pseudoreps/individual
python ./run_idr.py pseudoreplicate -d /share/samdata/yhliang/19advinformatics/wk6to10/Finalproject/H37/homer-tags /share/samdata/yhliang/19advinformatics/wk6to10/Finalproject/H38/homer-tags /share/samdata/yhliang/19advinformatics/wk6to10/Finalproject/H39/homer-tags -o pseudoreps/individual


# ------------------------------------------------------------------------------------------------
# Create pseudoreps for pooled (Step6)
# ------------------------------------------------------------------------------------------------
mkdir -p pseudoreps/pooled
python ./run_idr.py pseudoreplicate -d Combined -o pseudoreps/pooled


# ------------------------------------------------------------------------------------------------
# Call peaks for individual pseudoreps (Step 7)
# ------------------------------------------------------------------------------------------------
mkdir -p peaks/pseudoreps
cd peaks/pseudoreps
for f in ../../pseudoreps/individual/*
        do
	findPeaks $f -LP .1 -poisson .1 -style factor -size 150 -minDist 50 -localSize 50000 -o ${f}_peaks.txt
        done
cd ../../
# (/share/samdata/yhliang/19advinformatics/wk6to10/Finalproject/peakcalling-idr/150bp)


# ------------------------------------------------------------------------------------------------
# Call peaks for combined pseudoreps (Step 8)
# ------------------------------------------------------------------------------------------------
mkdir -p peaks/pooled-pseudoreps
cd peaks/pooled-pseudoreps
for f in ../../pseudoreps/pooled/*
        do
	findPeaks $f -LP .1 -poisson .1 -style factor -size 150 -minDist 50 -localSize 50000 -o ${f}_peaks.txt
        done
cd ../../
# (/share/samdata/yhliang/19advinformatics/wk6to10/Finalproject/peakcalling-idr/150bp)


# ------------------------------------------------------------------------------------------------
# Finally run IDR (Step 9)
# ------------------------------------------------------------------------------------------------
cp pseudoreps/individual/*peaks.txt peaks/pseudoreps/
cp pseudoreps/pooled/*peaks.txt peaks/pooled-pseudoreps/

python  ./run_idr.py idr \
        -p peaks/replicates/* \
        -pr peaks/pseudoreps/* \
        -ppr peaks/pooled-pseudoreps/* \
        --pooled_peaks Combined/combined.peaks.txt \
        -o idr-output \
        --threshold 0.005


# ------------------------------------------------------------------------------------------------
# Remove the scripts and code copied in step 1
# ------------------------------------------------------------------------------------------------
#rm -r idr_caller.py idrCode *.pyc run_idr.py utils.py __*


