rule fastuniq__deduplicate_reads:
    input:
        unpack(get_reads_for_deduplication),
    output:
        r1=temp("results/reads/deduplicated/{sample}_R1.fastq.gz"),
        r2=temp("results/reads/deduplicated/{sample}_R2.fastq.gz"),
        unzipped_out_r1=temp("results/reads/deduplicated/{sample}_R1.fastq"),
        unzipped_out_r2=temp("results/reads/deduplicated/{sample}_R2.fastq"),
        pair_description=temp("results/reads/deduplicated/{sample}.txt"),
    threads: min(config["threads"]["deduplication"], config["max_threads"])
    log:
        "logs/fastuniq/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/fastuniq/paired"
