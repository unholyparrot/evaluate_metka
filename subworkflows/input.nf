workflow INPUT {
    main:
        if (!params.input.endsWith(".csv")) {
            error "Input samplesheet must be a CSV file."
        }

        ch_raw_reads = channel
            .fromPath(params.input)
            .splitCsv(header: true)
            .map { row ->
                // 1. Валидация наличия базовых полей
                if (!row.sample || row.run == null) {
                    error "Invalid CSV: 'sample' and 'run' columns are mandatory. Row: $row"
                }
                
                // 2. Формирование структуры meta
                def meta = [:]
                meta.id         = row.sample
                meta.run        = row.run
                meta.single_end = row.short_reads_2 ? false : true
                
                // 3. Работа с файлами
                def r1 = row.short_reads_1 ? file(row.short_reads_1, checkIfExists: true) : null
                def r2 = row.short_reads_2 ? file(row.short_reads_2, checkIfExists: true) : null
                
                if (!r1) error "Short reads (R1) are missing for sample: ${meta.id}"

                if (!meta.single_end && r1 == r2) {
                    error "R1 and R2 files are identical for sample: ${meta.id}, run: ${meta.run}.\nPath: $r1"
                }
                
                def reads = meta.single_end ? r1 : [r1, r2]
                
                return [ meta, reads ]
            }

        // --- ПРОВЕРКА НА УНИКАЛЬНОСТЬ ---
        ch_raw_reads
            .map { meta, _reads -> [ "${meta.id}_${meta.run}", meta ] }
            .groupTuple()
            .map { _key, metas ->
                if (metas.size() > 1) {
                    error "Duplicate entry found in samplesheet for ID: ${metas[0].id} and Run: ${metas[0].run}"
                }
            }

    emit:
        raw_short_reads = ch_raw_reads
}
