rule fastuniq__deduplicate_reads:
    input:
        unpack(infer_fastqs_for_deduplication),
    output:
        r1=conf_temp("results/reads/deduplication/{sample}_R1.fastq.gz"),
        r2=conf_temp("results/reads/deduplication/{sample}_R2.fastq.gz"),
        unzipped_out_r1=temp("results/reads/deduplication/{sample}_R1.fastq"),
        unzipped_out_r2=temp("results/reads/deduplication/{sample}_R2.fastq"),
        pair_description=temp("results/reads/deduplication/{sample}.txt"),
    threads: min(config["threads"]["reads__deduplication"], config["max_threads"])
    log:
        "logs/fastuniq/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.12/wrappers/fastuniq/paired"
