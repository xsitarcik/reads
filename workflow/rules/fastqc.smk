rule fastqc__quality_report:
    input:
        read=infer_fastq_path,
    output:
        html=report(
            "results/reads/{step}/fastqc/{sample}_{pair}.html",
            category="{sample}",
            labels={
                "Type": "Fastqc {pair} - {step}",
            },
        ),
        zip="results/reads/{step}/fastqc/{sample}_{pair}.zip",
        qc_data="results/reads/{step}/fastqc/{sample}_{pair}/fastqc_data.txt",
        summary_txt="results/reads/{step}/fastqc/{sample}_{pair}/summary.txt",
    threads: min(config["threads"]["reads__fastqc"], config["max_threads"])
    resources:
        mem_mb=get_mem_mb_for_fastqc,
    log:
        "logs/fastqc/{step}/{sample}_{pair}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.12/wrappers/fastqc/quality"
