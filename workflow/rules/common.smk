from snakemake.utils import validate


configfile: "config/config.yaml"


validate(config, "../schemas/config.schema.yaml")


pepfile: config["pepfile"]


validate(pep.sample_table, "../schemas/samples.schema.yaml")


### Layer for adapting other workflows  ###############################################################################


### Data input handling independent of wildcards ######################################################################


def get_sample_names():
    return list(pep.sample_table["sample_name"].values)


def get_constraints():
    constraints = {
        "sample": "|".join(get_sample_names()),
    }
    return constraints


def get_one_fastq_file(sample: str, read_pair="fq1"):
    return pep.sample_table.loc[sample][[read_pair]]


def get_fastq_paths(sample: str):
    return pep.sample_table.loc[sample][["fq1", "fq2"]]


def get_last_step():
    return config["reads__processing_flow"][-1] if config["reads__processing_flow"] else None


### Contract for other workflows ######################################################################################


def get_final_fastq_for_sample(sample: str):
    if last_step := get_last_step():
        return expand(f"results/reads/{last_step}/{sample}_{{pair}}.fastq.gz", pair=["R1", "R2"])
    return get_fastq_paths(sample)


### Global rule-set stuff #############################################################################################


def get_outputs():
    outputs = {}
    sample_names = get_sample_names()
    if last_step := get_last_step():
        outputs["reads"] = expand(
            f"results/reads/{last_step}/{{sample}}_{{pair}}.fastq.gz", sample=sample_names, pair=["R1", "R2"]
        )

    if config["fastqc_reports"]:
        outputs["fastqc_report"] = expand(
            "results/reads/{step}/fastqc/{sample}_{pair}.html",
            step=config["fastqc_reports"],
            sample=sample_names,
            pair=["R1", "R2"],
        )

    return outputs


def get_previous_step_from_step(current_step: str):
    previous = "original"
    for step in config["reads__processing_flow"]:
        if step == current_step:
            return previous
        previous = step


def infer_fastq_path(wildcards):
    if wildcards.step != "original":
        return "results/reads/{step}/{sample}_{pair}.fastq.gz"
    if "pair" not in wildcards or wildcards.pair == "R1":
        return get_one_fastq_file(wildcards.sample, read_pair="fq1")[0]
    elif wildcards.pair == "R2":
        return get_one_fastq_file(wildcards.sample, read_pair="fq2")[0]


def get_reads_for_step(step: str, sample: str):
    if step != "original":
        return {
            "r1": f"results/reads/{step}/{sample}_R1.fastq.gz",
            "r2": f"results/reads/{step}/{sample}_R2.fastq.gz",
        }
    paths = get_fastq_paths(sample)
    return {
        "r1": paths[0],
        "r2": paths[1],
    }


def get_reads_for_decontamination(wildcards):
    return get_reads_for_step(get_previous_step_from_step("decontaminated"), wildcards.sample)


def get_reads_for_deduplication(wildcards):
    return get_reads_for_step(get_previous_step_from_step("deduplicated"), wildcards.sample)


def get_reads_for_trimming(wildcards):
    return get_reads_for_step(get_previous_step_from_step("trimmed"), wildcards.sample)


def get_reads_for_subsampling(wildcards):
    return get_reads_for_step(get_previous_step_from_step("subsampled"), wildcards.sample)


### Rule-granularity stuff ############################################################################################


def parse_adapter_removal_params():
    args_lst = []
    adapters_file = config["reads__trimming"]["adapter_removal"]["adapters_fasta"]
    read_location = config["reads__trimming"]["adapter_removal"]["read_location"]
    args_lst.append(f"--{read_location} file:{adapters_file}")

    if config["reads__trimming"]["adapter_removal"]["keep_trimmed_only"]:
        args_lst.append("--discard-untrimmed")

    args_lst.append(f"--action {config['reads__trimming']['adapter_removal']['action']}")
    args_lst.append(f"--overlap {config['reads__trimming']['adapter_removal']['overlap']}")
    args_lst.append(f"--times {config['reads__trimming']['adapter_removal']['times']}")
    args_lst.append(f"--error-rate {config['reads__trimming']['adapter_removal']['error_rate']}")
    return args_lst


def get_cutadapt_extra() -> list[str]:
    args_lst = []

    if "shorten_to_length" in config["reads__trimming"]:
        args_lst.append(f"--length {config['reads__trimming']['shorten_to_length']}")
    if "cut_from_start" in config["reads__trimming"]:
        args_lst.append(f"--cut {config['reads__trimming']['cut_from_start']}")
    if "cut_from_end" in config["reads__trimming"]:
        args_lst.append(f"--cut -{config['reads__trimming']['cut_from_end']}")
    if "max_n_bases" in config["reads__trimming"]:
        args_lst.append(f"--max-n {config['reads__trimming']['max_n_bases']}")
    if "max_expected_errors" in config["reads__trimming"]:
        args_lst.append(f"--max-expected-errors {config['reads__trimming']['max_expected_errors']}")

    if config["reads__trimming"]["adapter_removal"]["do"]:
        args_lst += parse_adapter_removal_params()

    return args_lst


def parse_paired_cutadapt_param(pe_config, param1, param2, arg_name) -> str:
    if param1 in pe_config:
        if param2 in pe_config:
            return f"{arg_name} {pe_config[param1]}:{pe_config[param2]}"
        else:
            return f"{arg_name} {pe_config[param1]}:"
    elif param2 in pe_config:
        return f"{arg_name} :{pe_config[param2]}"
    return ""


def parse_cutadapt_comma_param(config, param1, param2, arg_name) -> str:
    if param1 in config:
        if param2 in config:
            return f"{arg_name} {config[param2]},{config[param1]}"
        else:
            return f"{arg_name} {config[param1]}"
    elif param2 in config:
        return f"{arg_name} {config[param2]},0"
    return ""


def get_cutadapt_extra_pe() -> str:
    args_lst = get_cutadapt_extra()

    cutadapt_config = config["reads__trimming"]
    if parsed_arg := parse_paired_cutadapt_param(cutadapt_config, "max_length_r1", "max_length_r2", "--maximum-length"):
        args_lst.append(parsed_arg)
    if parsed_arg := parse_paired_cutadapt_param(cutadapt_config, "min_length_r1", "min_length_r2", "--minimum-length"):
        args_lst.append(parsed_arg)
    if qual_cut_arg_r1 := parse_cutadapt_comma_param(
        cutadapt_config, "quality_cutoff_from_3_end_r1", "quality_cutoff_from_5_end_r2", "--quality-cutoff"
    ):
        args_lst.append(qual_cut_arg_r1)
    if qual_cut_arg_r2 := parse_cutadapt_comma_param(
        cutadapt_config, "quality_cutoff_from_3_end_r1", "quality_cutoff_from_5_end_r2", "-Q"
    ):
        args_lst.append(qual_cut_arg_r2)
    return " ".join(args_lst)


def get_kraken_decontamination_params():
    extra = []
    if config["reads__decontamination"]["exclude_children"]:
        extra.append("--include-children")
    if config["reads__decontamination"]["exclude_ancestors"]:
        extra.append("--include-parents")
    return " ".join(extra)


### Resource handling #################################################################################################


def get_mem_mb_for_trimming(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["reads__trimming_mem_mb"] * attempt)


def get_mem_mb_for_fastqc(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["fastqc_mem_mb"] * attempt)
