include { BOWTIE2_BUILD } from './modules/nf-core/bowtie2/build/main'

include { INPUT } from './subworkflows/input.nf'

include {QC_CONTROLS as QC_CONTROLS_PRE} from './subworkflows/quality_check.nf'
include {CLEAN_READS} from './subworkflows/clean_reads.nf'
// include {QC_CONTROLS as QC_CONTROLS_POST} from './subworkflows/quality_check.nf'

include { MULTIQC } from './modules/nf-core/multiqc/main'


workflow {
    ch_multiqc_files = channel.empty()

    INPUT()

    ch_index = channel.empty()
        
    if (params.reference_bowtie2_index) {
        // Если индекс уже есть, берем файлы из папки
        ch_index = channel
            .fromPath("${params.reference_bowtie2_index}/*.bt2*")
            .collect()
    } else {
        // Если индекса нет, запускаем сборку
        // Передаем [ [id:'reference'], fasta ]
        ch_index = BOWTIE2_BUILD ( [ [id: 'reference'], params.reference_fasta ] ).index
    }

    QC_CONTROLS_PRE(INPUT.out.raw_short_reads, "raw", ch_index)



}
