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
