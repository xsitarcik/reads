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
