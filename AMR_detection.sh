#!/bin/bash

#if Miniconda is not installed, then make sure you download Miniconda for your Linux system and then start

#Create a new GCP bucket for the project. Ensure this Bucket has Public Access
gsutil mb -l us-west1 gs://cs123b-proj-bucket

#create a new directory for the project cs123b-project and sub directory plasmids
mkdir ~/cs123b
mkdir ~/cs123b/plasmids
mkdir ~/cs123b/plasmids/raw_fasta_files

#download the sample fasta files from the web
wget -P ~/cs123b/plasmids/raw_fasta_files https://zenodo.org/record/3247504/files/RB01.fasta
wget -P ~/cs123b/plasmids/raw_fasta_files https://zenodo.org/record/3247504/files/RB02.fasta
wget -P ~/cs123b/plasmids/raw_fasta_files https://zenodo.org/record/3247504/files/RB04.fasta
wget -P ~/cs123b/plasmids/raw_fasta_files https://zenodo.org/record/3247504/files/RB05.fasta
wget -P ~/cs123b/plasmids/raw_fasta_files https://zenodo.org/record/3247504/files/RB10.fasta
wget -P ~/cs123b/plasmids/raw_fasta_files https://zenodo.org/record/3247504/files/RB12.fasta

#List all the fasta files downloaded from the web
ls -al

#install all the channels we need - bioconda and conda-forge
conda config --show channels
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --show channels

#conda create nanoplot env
conda create -n nanoplot_env -y
conda activate nanoplot_env
conda install -c bioconda nanoplot -y
which NanoPlot

#make sure you are in ~/cs123b/plasmids/raw_fasta_files directory
cd ~/cs123b/plasmids/raw_fasta_files/

for fasta_file in *.fasta; do
    echo "Running NanoPlot on $fasta_file"
    NanoPlot --fasta $fasta_file --outdir ~/cs123b/plasmids/nanoplot_output/$(basename $fasta_file .fasta)_nanoplot --plots dot
done

#Running Minimap2
conda create -n minimap2_env -y
conda activate minimap2_env
conda install -c bioconda minimap2 -y
#check to make sure minimap2 is installed in the correct environment
which minimap2

#make sure you are in ~/cs123b/plasmids/raw_fasta_files directory
cd ~/cs123b/plasmids/raw_fasta_files/

for fasta_file in *.fasta; do output_name=$(basename "$fasta_file" .fasta)_vs_Plasmids.paf
    minimap2 -x ava-ont --paf-no-hit -o $output_name $fasta_file *.fasta
done

mkdir ~/cs123b/plasmids/minimap2_output
mv *.paf ~cs123b/plasmids/minimap2


#Running Unicycler
conda create -n unicycler_env -y
conda activate unicycler_env
conda install -c bioconda unicycler -y
#check to make sure unicycler is installed in the correct environment
which unicycler

mkdir ~/cs123b/plasmids/unicycler_output

#make sure you are in ~/cs123b/plasmids/raw_fasta_files directory
for fasta in *.fasta; do
    unicycler -l $fasta -o ./unicycler_output/$(basename "$fasta" .fasta)_unicycler
done

#Running Bandage
conda create -n bandage_env -y
conda activate bandage_env

#Bandage took a long time to install. It required qt5 to be installed and configured
#Go to Bandage website and download the Linux compatible file of Bandage and unzip it
#Download QT5 from their website, unzip it and configure it. 


for gfa in *.gfa; do  Bandage image $gfa $(basename "$gfa" .gfa).png; done
mkdir ~/cs123b/plasmids/bandage_output/RB04_bandage_output
mv *.png ~/cs123b/plasmids/bandage_output/RB04_bandage_output

#Running PlasFlow - to predict whether contigs originate from Plasmid or Chromosomal source
#PlasFlow has a dependeny on Python 3.5 and TensorFlow
conda create -n plasflow_env -y
conda activate plasflow_env
conda create --name plasflow python=3.5
conda activate plasflow
conda install -c jjhelmus tensorflow=0.10.0rc0
conda install plasflow -c smaegol
which PlasFlow

PlasFlow.py --input assembly.fasta --output-dir ~/cs123b/plasmids/plasflow_output/RB01_plasflow_output

#Running Staramr - Scanning for the Anti Microbial Resistance Genes in each of the 6 samples
conda create -n staramr_env -y
conda activate staramr_env
conda install -c bioconda staramr -y
which staramr

staramr search assembly.fasta -o ~cs123b/plasmids/staramr_output/RB01_staramr_output

#Copying all the data to GCP VM using gsutil
gsutil cp -r ~/cs123b gs://cs123b-proj-bucket/cs123b
