rule cutadapt__trim_reads_pe:
    input:
        unpack(get_reads_for_trimming),
    output:
        r1=temp("results/reads/trimmed/{sample}_R1.fastq.gz"),
        r2=temp("results/reads/trimmed/{sample}_R2.fastq.gz"),
        report=temp("results/reads/trimmed/{sample}_cutadapt.json"),
    params:
        extra=get_cutadapt_extra_pe(),
    resources:
        mem_mb=get_mem_mb_for_trimming,
    threads: min(config["threads"]["reads__trimming"], config["max_threads"])
    log:
        "logs/cutadapt/trim_reads_pe/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/cutadapt/paired"
