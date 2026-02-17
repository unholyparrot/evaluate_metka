include { BOWTIE2_BUILD as BOWTIE2_BUILD_REFERENCE } from './modules/nf-core/bowtie2/build/main'
include { BOWTIE2_BUILD as BOWTIE2_BUILD_HOST } from './modules/nf-core/bowtie2/build/main'

include { INPUT } from './subworkflows/input.nf'

include {QC_CONTROLS as QC_CONTROLS_PRE} from './subworkflows/quality_check.nf'
include {CLEAN_READS} from './subworkflows/clean_reads.nf'
include {QC_CONTROLS as QC_CONTROLS_POST} from './subworkflows/quality_check.nf'

include { MULTIQC } from './modules/nf-core/multiqc/main'


workflow {
    ch_multiqc_files = channel.empty()

    INPUT()

    ch_index_reference = channel.empty()
        
    if (params.reference_bowtie2_index) {
        // Если индекс уже есть, берем файлы из папки
        ch_index_reference = channel
            .fromPath("${params.reference_bowtie2_index}/")
            .map {
                it -> [[id: 'host'], it]
            }
            .collect()
    } else {
        // Если индекса нет, запускаем сборку
        // Передаем [ [id:'reference'], fasta ]
        ch_index_reference = BOWTIE2_BUILD_REFERENCE ( [ [id: 'reference'], params.reference_fasta ] ).index
    }

    ch_index_host = channel.empty()

    if (params.host_bowtie2_index) {
        // Если индекс уже есть, берем файлы из папки
        ch_index_host = channel
            .fromPath("${params.host_bowtie2_index}/")
            .map {
                it -> [[id: 'host'], it]
            }
            .collect()
    } else {
        // Если индекса нет, запускаем сборку
        // Передаем [ [id:'reference'], fasta ]
        ch_index_host = BOWTIE2_BUILD_HOST ( [ [id: 'host'], params.host_fasta ] ).index
    }

    QC_CONTROLS_PRE(INPUT.out.raw_short_reads, "raw", ch_index_reference)
    ch_multiqc_files = ch_multiqc_files.mix(QC_CONTROLS_PRE.out.multiqc_files.collect())
    
    CLEAN_READS(INPUT.out.raw_short_reads, ch_index_host)
    ch_multiqc_files = ch_multiqc_files.mix(CLEAN_READS.out.multiqc_files.collect())

    QC_CONTROLS_POST(CLEAN_READS.out.clean_reads, "clean", ch_index_reference)
    ch_multiqc_files = ch_multiqc_files.mix(QC_CONTROLS_POST.out.multiqc_files.collect())

    MULTIQC(ch_multiqc_files.collect(), [], [], [], [], [])

}
