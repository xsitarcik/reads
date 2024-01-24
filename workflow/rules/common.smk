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


def get_read_processing_steps() -> list[str]:
    return [step for step in config["reads"] if not step.startswith("_")]


def get_last_step() -> str | None:
    steps = get_read_processing_steps()
    return steps[-1] if steps else None


def get_previous_step_from_step(current_step: str):
    previous = "original"
    for step in get_read_processing_steps():
        if step == current_step:
            return previous
        previous = step


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

    if config["reads"]["_generate_fastqc_for"]:
        outputs["fastqc_report"] = expand(
            "results/reads/{step}/fastqc/{sample}_{pair}.html",
            step=config["reads"]["_generate_fastqc_for"],
            sample=sample_names,
            pair=["R1", "R2"],
        )

    return outputs


def infer_fastq_path(wildcards):
    if wildcards.step != "original":
        return "results/reads/{step}/{sample}_{pair}.fastq.gz"
    if "pair" not in wildcards or wildcards.pair == "R1":
        return get_one_fastq_file(wildcards.sample, read_pair="fq1")[0]
    elif wildcards.pair == "R2":
        return get_one_fastq_file(wildcards.sample, read_pair="fq2")[0]


def infer_fastqs_for_decontamination(wildcards):
    return get_reads_for_step(get_previous_step_from_step("decontamination"), wildcards.sample)


def infer_fastqs_for_deduplication(wildcards):
    return get_reads_for_step(get_previous_step_from_step("deduplication"), wildcards.sample)


def infer_fastqs_for_trimming(wildcards):
    return get_reads_for_step(get_previous_step_from_step("trimming"), wildcards.sample)


def infer_fastqs_for_subsampling(wildcards):
    return get_reads_for_step(get_previous_step_from_step("subsampling"), wildcards.sample)


### Rule-granularity stuff ############################################################################################


def parse_adapter_removal_params(adapter_config):
    args_lst = []
    adapters_file = adapter_config["adapters_fasta"]
    read_location = adapter_config["read_location"]

    if read_location == "front":
        paired_arg = "-G"
    elif read_location == "anywhere":
        paired_arg = "-B"
    elif read_location == "adapter":
        paired_arg = "-A"

    args_lst.append(f"--{read_location} file:{adapters_file} {paired_arg} file:{adapters_file}")

    if adapter_config["keep_trimmed_only"]:
        args_lst.append("--discard-untrimmed")

    args_lst.append(f"--action {adapter_config['action']}")
    args_lst.append(f"--overlap {cadapter_config['overlap']}")
    args_lst.append(f"--times {adapter_config['times']}")
    args_lst.append(f"--error-rate {adapter_config['error_rate']}")
    return args_lst


def get_cutadapt_extra(cutadapt_config) -> list[str]:
    args_lst = []

    if value := cutadapt_config.get("shorten_to_length", None):
        args_lst.append(f"--length {value}")
    if value := cutadapt_config.get("cut_from_start_r1", None):
        args_lst.append(f"--cut {value}")
    if value := cutadapt_config.get("cut_from_start_r2", None):
        args_lst.append(f"-U {value}")
    if value := cutadapt_config.get("cut_from_end_r1", None):
        args_lst.append(f"--cut -{value}")
    if value := cutadapt_config.get("cut_from_end_r2", None):
        args_lst.append(f"-U -{value}")

    if value := cutadapt_config.get("max_n_bases", None):
        args_lst.append(f"--max-n {value}")
    if value := cutadapt_config.get("max_expected_errors", None):
        args_lst.append(f"--max-expected-errors {value}")
    if value := cutadapt_config.get("trim_N_bases_on_ends", None):
        args_lst.append(f"--trim-n")

    if cutadapt_config["adapter_removal"]["do"]:
        args_lst += parse_adapter_removal_params(cutadapt_config["adapter_removal"])

    return args_lst


def parse_paired_cutadapt_param(pe_config, param1, param2, arg_name) -> str:
    if pe_config[param1]:
        if pe_config[param2]:
            return f"{arg_name} {pe_config[param1]}:{pe_config[param2]}"
        else:
            return f"{arg_name} {pe_config[param1]}:"
    elif pe_config[param2]:
        return f"{arg_name} :{pe_config[param2]}"
    return ""


def parse_cutadapt_comma_param(cutadapt_config, param1, param2, arg_name) -> str:
    if cutadapt_config[param1]:
        if cutadapt_config[param2]:
            return f"{arg_name} {cutadapt_config[param2]},{cutadapt_config[param1]}"
        else:
            return f"{arg_name} {cutadapt_config[param1]}"
    elif cutadapt_config[param2]:
        return f"{arg_name} {cutadapt_config[param2]},0"
    return ""


def get_cutadapt_extra_pe() -> str:
    cutadapt_config = config["reads__trimming__cutadapt"]

    args_lst = get_cutadapt_extra(cutadapt_config)

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
    if config["reads__decontamination__kraken"]["exclude_children"]:
        extra.append("--include-children")
    if config["reads__decontamination__kraken"]["exclude_ancestors"]:
        extra.append("--include-parents")
    return " ".join(extra)


### Resource handling #################################################################################################


def get_mem_mb_for_trimming(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["reads__trimming_mem_mb"] * attempt)


def get_mem_mb_for_fastqc(wildcards, attempt):
    return min(config["max_mem_mb"], config["resources"]["fastqc_mem_mb"] * attempt)
