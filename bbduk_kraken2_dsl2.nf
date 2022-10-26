#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*  Comments are uninterpreted text included with the script.
    They are useful for describing complex parts of the workflow
    or providing useful information such as workflow usage.

    Usage:
       nextflow run wc.nf --input <input_file>

    Multi-line comments start with a slash asterisk /* and finish with an asterisk slash. */
//  Single line comments start with a double slash // and finish on the same line

/*  Workflow parameters are written as params.<parameter>
    and can be initialised using the `=` operator. */
params.reads = "fastqs/*_{R1,R2}_*.fastq.gz"

//  The default workflow
workflow {

    //  Input data is received through channels
    read_pairs_ch = channel.fromFilePairs(params.reads)

    /*  The script to execute is called by its process name,
        and input is provided between brackets. */
    //NUM_LINES(input_ch)
    BBDUK(read_pairs_ch)
    KRAKEN(BBDUK.out)

    /*  Process output is accessed using the `out` channel.
        The channel operator view() is used to print
        process output to the terminal. */
    NUM_LINES.out.view()
}

/*  A Nextflow process block
    Process names are written, by convention, in uppercase.
    This convention is used to enhance workflow readability. */
process NUM_LINES {

    input:
    path read

    output:
    stdout

    script:
    /* Triple quote syntax """, Triple-single-quoted strings may span multiple lines. The content of the string can cross line boundaries without the need to split the string in several pieces and without concatenation or newline escape characters. */
    """
    printf '${read} '
    gunzip -c ${read} | wc -l
    """
}

//process 1: Adapter and quality trimming using bbduk
process BBDUK {
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
process KRAKEN {
        tag "$name"
        publishDir 'fastqs-trimmed-kraken2'

        input:
        set pair_id, file(reads) from kraken2_input

        output:
        file "*_kraken2_report.txt"
        file "*_kraken2_output.krona.html"

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