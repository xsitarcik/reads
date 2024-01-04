rule custom__infer_and_store_read_group:
    input:
        get_one_fastq_file,
    output:
        read_group="results/reads/original/read_group/{sample}.txt",
    params:
        sample_id=lambda wildcards: wildcards.sample,
    log:
        "logs/custom/infer_and_store_read_group/{sample}.log",
    wrapper:
        "https://github.com/xsitarcik/wrappers/raw/v1.12.6/wrappers/custom/read_group"
