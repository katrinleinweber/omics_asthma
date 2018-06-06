# asthma ER vs DR

**purpose**: human asthma patients experience an asthma attack or constriction in their airways upon contact with allergens. a subgroup of these patients will recover after their initial attack. however, some will suffer from inflammation some hours later.
- hence this project aims to find biomarkers that differentiates between patents who
  - will (dual response DR) and
  - will not suffer from this second wave of inflammation (exacerbation ER)
- from blood sampled
  - before allergen contact and
  - a few hours after the initial asthma attack (theoretically some time before a possible second wave of inflammation).


**input**:
- data
  - RNAseq (.fastq files)
  - Genotyping (affymetrix axiom .calls matrix): note there is one genotyping DNA data per patient

- folder structure before running anything

```

├─── code (this repository)
├──+ data
|  ├─+ genotype
|  | ├── plink (plink software for imputation)
|  | └── hapmap (hapmap ref for imputation)
|  ├─+ RNAseq
|  | └── fastq (folder containing .fastq files)
|  └── reference_SNP

```



## Data pre-processing



### RNAseq

#### input raw fastq > output sample x base/isoform/gene matrix of counts/abundence
1. install packages required: **fastqc** > **star** > **rsem**
  - one of the easiest ways to do this is via [python](https://docs.python.org/3/using/unix.html#getting-and-installing-the-latest-version-of-python) and then [conda](https://conda.io/docs/user-guide/install/index.html#installing-conda-on-a-system-that-has-other-python-installations-or-packages) after which you can create an environment to install your packages in. click on the links to see how to do this in your respective operating system. linux example below.

```bash

#install miniconda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

#create an environment to install the packages in
conda env create --name myenv_py3 --file environment.yaml

#install the packages via conda; searchable via https://anaconda.org/
conda install -c bioconda fastqc
conda install -c bioconda star
conda install -c bioconda rsem

#conda install -c r r #r packages for putting together the final matrix; optional
#conda install -c r r-dplyr 

#load the environment
source activate myenv_py3

```


2. given a folder of raw fastq files, run fastQC (optional if fastQC is already done), STAR (map transcripts to the organism's genome e.g. [GRC](https://www.ncbi.nlm.nih.gov/grc)), and RSEM (get abundence). to do so, first **write the raw fastq file paths into [config.yaml](./config.yaml)** (we write all the file names to keep a record, you can also specify a folder) and then run [Snakefile](./Snakefile) (adapted from the (Sakemake pipeline)[https://snakemake.readthedocs.io/en/stable/]). note: if there is more than one run of a sample (i.e. more than one fastq file per sample), put them together! linux example below.

```bash
#write raw fastq file paths into config.yaml
#run snakemake; its configurations and parameters are in config.yaml
snakemake -np --cores 6 #dry run
snakemake -p --cores 6 #actual run; change the number of cores as needed

```

3. given the <sample>.<genes/isoforms>.results rsem output files for each fastq file, ([nice link](https://ycl6.gitbooks.io/rna-seq-data-analysis/quantification_using_rsem1.html)) consolidate them into a count matrix. linux example below.

```bash
#run count1.sh
chmod u+x count1.sh
./count1.sh

```





### genotype (Affymetrix Axiom)
- converting probe id to SNP id: [GeneChip Array Annotation Files](https://www.thermofisher.com/ca/en/home/life-science/microarray-analysis/microarray-data-analysis/genechip-array-annotation-files.html)


#### imputation
using **ricopili** to infer continuous probabilistic values for missing SNPs using reference HapMap data; original tutorial [here](https://sites.google.com/a/broadinstitute.org/ricopili/). there are other options such as splink2, whichever one is suitable.

- install recopili into the  (replace *<version>* with latest file from the [downloads page](https://sites.google.com/a/broadinstitute.org/ricopili/download)). 

```
#download and install ricopili
wget https://sites.google.com/a/broadinstitute.org/ricopili/download//rp_bin.<version>.tar.gz
#wget https://sites.google.com/a/broadinstitute.org/ricopili/download//rp_bin.2018_May_28.001.tar.gz

tar -xvzf rp_bin.<version>.tar.gz
#tar -xvzf rp_bin.2018_May_28.001.tar.gz


```

- download [hapmap reference data](http://zzz.bwh.harvard.edu/plink/res.shtml) (linked 20180531) for whichever race / all races you prefer and unzip into the **hapmap** folder.
- 





