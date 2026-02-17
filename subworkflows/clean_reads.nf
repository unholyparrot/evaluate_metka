include { FASTP } from '../modules/nf-core/fastp/main'
include { BOWTIE2_ALIGN } from '../modules/nf-core/bowtie2/align/main'

workflow CLEAN_READS {
    take:
        input_reads
        index
    
    main:
        ch_multiqc_files = channel.empty()
        FASTP(
            input_reads.map{it -> [it[0], it[1], []]},
            false,
            false,
            false
        )
        ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.collect{it[1]}.ifEmpty([]))

        BOWTIE2_ALIGN(
            FASTP.out.reads, 
            index,
            [ [id:'host'], params.host_fasta], 
            true, // save unaligned
            false // do not sort
        )
        ch_multiqc_files = ch_multiqc_files.mix(BOWTIE2_ALIGN.out.log.collect{it[1]}.ifEmpty([]))
    
    emit:
        clean_reads = BOWTIE2_ALIGN.out.fastq
        multiqc_files = ch_multiqc_files
}
