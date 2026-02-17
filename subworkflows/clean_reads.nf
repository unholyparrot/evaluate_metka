include { FASTP } from '../modules/nf-core/fastp/main'

workflow CLEAN_READS {
    take:
        input_reads
    
    main:
        FASTP(
            input_reads.map{it -> [it[0], it[1], []]},
            false,
            false,
            false
        )

    
    emit:
        clean_reads
}