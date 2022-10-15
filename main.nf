#! /usr/bin/env nextflow

blastdb="genome.fa"
params.query="file.fasta"

println "I will BLAST $params.query against $blastdb"
