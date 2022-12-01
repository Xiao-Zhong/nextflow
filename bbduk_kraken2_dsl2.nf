//process_tuple_io_fastp.nf
nextflow.enable.dsl=2

process BBDUK {
    tag {pair_id}
    publishDir 'fastqs-trimmed'

    input:
    tuple val(sample_id), path(reads)
    
    output:
    tuple val(sample_id), path("*.bbduk.fastq.gz")
    path "${sample_id}.stats.txt"
    path "${sample_id}.bbduk.sh.err"

    script:
    """
    bbduk.sh \
        in1=${reads[0]} \
        in2=${reads[1]} \
        ref=${params.adapters} \
        out1=${reads[0].baseName}.bbduk.fastq.gz \
        out2=${reads[1].baseName}.bbduk.fastq.gz \
        stats=${sample_id}.stats.txt \
        forcetrimleft=${params.trimleft} \
        ktrim=r \
        k=23 \
        mink=11 \
        hdist=1 \
        tpe \
        tbo 2>${sample_id}.bbduk.sh.err
    """
}

//process 2: seqeunce classification and visualisation using kraken2
process KRAKEN {
    tag {pair_id}
    publishDir 'fastqs-trimmed-kraken2'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "*_kraken2_report.txt"
    path "*_kraken2_output.krona.html"

    """
    kraken2 \
        --threads ${params.cpus} \
        --db ${params.db} \
        --paired ${reads[0]} ${reads[1]} \
        --report ${sample_id}_kraken2_report.txt \
        --output ${sample_id}_kraken2_output.txt 

    cat ${sample_id}_kraken2_output.txt | cut -f 2,3 > ${sample_id}_kraken2_output.krona
    ktImportTaxonomy -o ${sample_id}_kraken2_output.krona.html ${sample_id}_kraken2_output.krona
    """
}

reads_ch = Channel.fromFilePairs('fastqs/*_{R1,R2}_*.fastq.gz')
params.adapters = '/SOFTWARE/bbmap-38.96/resources/adapters.fa'
// adapters_ch = channel.fromPath(params.adapters)
params.trimleft = 0

params.cpus = 30
params.db = "/genomics/reference/kraken2/db-CW644-v110"

workflow {
    BBDUK(reads_ch)
    //BBDUK.out[0].view()
    KRAKEN(BBDUK.out[0])
}
