rule curl__download_kraken_db:
    output:
        protected("{prefix_dir}/hash.k2d"),
    params:
        url=lambda wildcards, output: "https://genome-idx.s3.amazonaws.com/kraken/{tag}.tar.gz".format(
            tag=os.path.basename(os.path.dirname(output[0]))
        ),
        dirpath=lambda wildcards, output: os.path.dirname(output[0]),
    retries: 1
    log:
        "{prefix_dir}/logs/download.log",
    conda:
        "../envs/curl.yaml"
    shell:
        "(mkdir -p {params.dirpath} && curl -SL {params.url} | tar zxvf - -C {params.dirpath}) > {log} 2>&1"


rule kraken__analysis:
    input:
        get_reads_for_decontamination,
        kraken_tax=os.path.join(config["decontamination"]["kraken_dir"], "hash.k2d"),
    output:
        kraken_output=temp("results/kraken/{sample}.kraken"),
        report="results/kraken/{sample}.kreport2",
    params:
        save_memory="--memory-mapping" if config["decontamination"]["save_memory"] else "",
        db_dir=lambda wildcards, input: os.path.dirname(input.kraken_tax),
    threads: min(config["threads"]["decontamination"], config["max_threads"])
    log:
        "logs/kraken/analysis/{sample}.log",
    conda:
        "../envs/kraken2.yaml"
    shell:
        "(kraken2 --db {params.db_dir} --threads {threads} --paired --gzip-compressed"
        " {params.save_memory} --report {output.report} {input.r1} {input.r2} 1> {output.kraken_output}) 2> {log}"
