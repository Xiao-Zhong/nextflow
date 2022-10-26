#!/usr/bin/env nextflow
nextflow.enable.dsl = 1

params.reads = "fastqs/*_{R1,R2}_*.fastq.gz"
params.cpus = 30

params.adapters = "/SOFTWARE/bbmap-38.96/resources/adapters.fa"
params.trimleft = 0
params.db = "/genomics/reference/kraken2/db-CW644-v110"


//create in put_channel
adapters_file = file(params.adapters)

//Creates the `read_pairs` channel that emits for each read-pair a tuple containing
//three elements: the pair ID, the first read-pair file and the second read-pair file
Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .set { read_pairs }

//process 1: Adapter and quality trimming using bbduk
process bbduk {
        tag {pair_id}
        publishDir 'fastqs-trimmed'

        input:
        set pair_id, file(reads) from read_pairs
        file adapters_file

        output:
        set pair_id, file("*.bbduk.fastq.gz") into kraken2_input
        file "${pair_id}.stats.txt"
        file "${pair_id}.bbduk.sh.err"

        script:
        """
        bbduk.sh \
             in1=${reads[0]} \
             in2=${reads[1]} \
             ref=${adapters_file} \
             out1="${reads[0].baseName}.bbduk.fastq.gz" \
             out2="${reads[1].baseName}.bbduk.fastq.gz" \
             stats=${pair_id}.stats.txt \
             forcetrimleft=${params.trimleft} \
             ktrim=r \
             k=23 \
             mink=11 \
             hdist=1 \
             tpe \
             tbo 2>${pair_id}.bbduk.sh.err
        """
}

//process 2: seqeunce classification and visualisation using kraken2
process kraken {
        tag "$name"
        publishDir 'fastqs-trimmed-kraken2'


        input:
        set pair_id, file(reads) from kraken2_input

        output:
        file "*_fastqc.{zip,html}" into kraken2_output


        """
        kraken2 \
          --threads ${params.cpus} \
          --db ${params.db} \
          --paired ${reads[0]} ${reads[1]} \
          --report ${pair_id}_kraken2_report.txt \
          --output ${pair_id}_kraken2_output.txt 


          cat ${pair_id}_kraken2_output.txt | cut -f 2,3 > ${pair_id}_kraken2_output.krona
          ktImportTaxonomy -o ${pair_id}_kraken2_output.krona.html ${pair_id}_kraken2_output.krona

        """
}
