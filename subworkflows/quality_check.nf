include { FASTQC } from '../modules/nf-core/fastqc/main'
include { KRAKEN2_KRAKEN2 } from '../modules/nf-core/kraken2/kraken2/main'
include { BOWTIE2_ALIGN } from '../modules/nf-core/bowtie2/align/main'
include { SAMTOOLS_INDEX } from '../modules/nf-core/samtools/index/main'
include { SAMTOOLS_DEPTH } from '../modules/nf-core/samtools/depth/main'


workflow QC_CONTROLS {
    take:
        input_reads // [meta, [reads]]
        suffix     // String to append to output names (e.g., 'pre_qc' or 'post_qc')
        index 
        
    main:
        ch_multiqc_files = channel.empty()

        // Modify meta to include the suffix
        input_reads_modified = input_reads.map { meta, reads ->
            def new_meta = meta.clone()
            new_meta.id = "${meta.id}_${suffix}"
            [new_meta, reads]
        }

        FASTQC(input_reads_modified)
        ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

        KRAKEN2_KRAKEN2(input_reads_modified, params.db_kraken2, false, false)

        BOWTIE2_ALIGN(
            input_reads_modified, 
            index,
            [ [id:'ref'], params.reference_fasta], 
            false, 
            true
        )

        SAMTOOLS_INDEX(
            BOWTIE2_ALIGN.output.bam
        )

        SAMTOOLS_DEPTH(
            BOWTIE2_ALIGN.output.bam.combine(
                SAMTOOLS_INDEX.output.bai,
                by: 0
            ).map {
                it -> [it[0], it[1], it[2]]
            },
            [[id: 'empty'], []]
        )


    emit:
        multiqc_files = ch_multiqc_files
}
