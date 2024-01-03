rule seqtk__subsample_reads_pe:
    input:
        unpack(get_reads_for_subsampling),
    output:
        r1=temp("results/reads/subsampled/{sample}_R1.fastq.gz"),
        r2=temp("results/reads/subsampled/{sample}_R2.fastq.gz"),
    params:
        seed=config["subsampling"]["seed"],
        n_reads=config["subsampling"]["n_reads"],
        reduce_memory=config["subsampling"]["reduce_memory"],
    log:
        "logs/seqtk/subsample_reads_pe/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/seqtk/subsample_paired"


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
    threads: min(config["threads"]["trimming"], config["max_threads"])
    log:
        "logs/cutadapt/trim_reads_pe/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/cutadapt/paired"


rule kraken__decontaminate:
    input:
        unpack(get_reads_for_decontamination),
        kraken_output="results/kraken/{sample}.kraken",
        kraken_report="results/kraken/{sample}.kreport2",
    output:
        r1="results/reads/decontaminated/{sample}_R1.fastq.gz",
        r2="results/reads/decontaminated/{sample}_R2.fastq.gz",
        std_out=temp("results/reads/decontaminated/{sample}_decontamination.out"),
    params:
        taxid=" ".join(str(taxa_id) for taxa_id in config["decontamination"]["exclude_taxa_ids"]),
        extra=get_kraken_decontamination_params(),
    log:
        "logs/kraken/decontaminate/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/kraken/decontaminate_pe"


rule fastuniq__deduplicate_reads:
    input:
        unpack(get_reads_for_deduplication),
    output:
        r1="results/reads/deduplicated/{sample}_R1.fastq.gz",
        r2="results/reads/deduplicated/{sample}_R2.fastq.gz",
        unzipped_out_r1=temp("results/reads/deduplicated/{sample}_R1.fastq"),
        unzipped_out_r2=temp("results/reads/deduplicated/{sample}_R2.fastq"),
        pair_description=temp("results/reads/deduplicated/{sample}.txt"),
    threads: min(config["threads"]["deduplication"], config["max_threads"])
    log:
        "logs/fastuniq/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/fastuniq/paired"


rule fastqc__quality_report:
    input:
        read=infer_fastq_path,
    output:
        html=report(
            "results/reads/{step}/fastqc/{sample}_{orientation}.html",
            category="{sample}",
            labels={
                "Type": "Fastqc {orientation} - {step}",
            },
        ),
        zip="results/reads/{step}/fastqc/{sample}_{orientation}.zip",
        qc_data="results/reads/{step}/fastqc/{sample}_{orientation}/fastqc_data.txt",
        summary_txt="results/reads/{step}/fastqc/{sample}_{orientation}/summary.txt",
    threads: min(config["threads"]["fastqc"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_fastqc,
    log:
        "logs/fastqc/{step}/{sample}_{orientation}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/fastqc/quality"
