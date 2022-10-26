read_pair_ch = Channel.fromFilePairs("fastqs/*_{R1,R2}_*.fastq.gz")

read_pair_ch.view()

// x = read_pair_ch[1]
// x.view()e