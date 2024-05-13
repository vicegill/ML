# Snakemake file for simulating the bottleneck
import random
import subprocess
import time


def check_job_status():
    while True:
        result = subprocess.run(["squeue","--cluster","biohpc_gen","-u","ra78pec"],capture_output =True , text= True)
        output = result.stdout.strip().split("\n")
        job_lines = output[2:]
        
        if len(job_lines) == 0:
            print("No jobs in the queue. Proceeding...")
            break
        
        print("Jobs still in the queue. Waiting...")
        
        time.sleep(60)

configfile : "workflow/config_bottleneck.yaml"
factors = config["factors"]

with open("output/output_bottleneck/bottleneck_coeffecient.txt") as f:
    global bottleneck_coeffecients
    bottleneck_coeffecients = [line.strip() for line in f]
rule all:
    input:
        "output/output_bottleneck/dag.png",
        expand("output/output_bottleneck/bottleneck_txt/bottleneck_{coef}.txt",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/bottleneck_trees/bottleneck_{coef}.trees",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/vcf/bottleneck_{coef}.vcf",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/ancestral_sequence/ancestral_{coef}.fasta",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/images/image_{coef}.png",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/h_format/h_{coef}.csv",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/fasta/bottleneck_{coef}.fasta",coef= bottleneck_coeffecients),
        expand("output/output_bottleneck/h_result/h_{coef}.txt",coef=bottleneck_coeffecients),
        "output/output_bottleneck/meta_data/meta_Stats.tab",
        "output/output_bottleneck/meta_data/meta_images.tab",
        "output/output_bottleneck/meta_data/metadata_h.tab",
        f"output/output_bottleneck/final_page_{config['batch_size']}.txt",
        "output/output_bottleneck/meta_file.tab"


rule debug:
    shell:
        "conda info"

rule dag:
    output:
        "output/output_bottleneck/dag.png"
    run:
        shell("mkdir -p output/output_bottleneck")
        shell("snakemake --dag -s workflow/simulate_bottleneck.smk | dot -Tpng > output/output_bottleneck/dag.png")

rule slim:
    input:
       "workflow/bottleneck.slim",
       "output/output_bottleneck/bottleneck_coeffecient.txt"
    output:
        expand("output/output_bottleneck/bottleneck_trees/bottleneck_{coef}.trees",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/temp_slim/bottleneck_{coef}.slim",coef=bottleneck_coeffecients)
    params:
        slim_executable="/dss/dsshome1/09/ra78pec/mambaforge/envs/snakemake/bin/slim",
        # Add the location of your slim executable here (use "wheris slim")
        mutation_rate=factors["mutation_rate"],
        recombination_rate=factors["recombination_rate"],
        population_size=factors["population_size"],
        sequence_length=factors["sequence_length"],
        stop_generation=factors["when_bottleneck"]
    run:
        # Iterate through bottleneck coefficients 
        shell("mkdir -p output/output_bottleneck/bottleneck_trees/log")
        shell("mkdir -p output/output_bottleneck/temp_slim")
        shell("mkdir -p output/output_bottleneck/temp_sbtach")
        shell("mkdir -p temp/slim")
        i=1
        jobs = []
        for b in bottleneck_coeffecients:
            input_unique=f"output/output_bottleneck/temp_slim/bottleneck_{b}.slim"
            shell("touch {input_unique}")
            # Update the stop_generation value in the script
            with open(input[0], "r") as file:
              script_content = file.read()
              script_content = script_content.replace("when_bottleneck", f"{params.stop_generation}")
            with open(input_unique, "w") as file:
              file.write(script_content)
            output_file2 =f"output/output_bottleneck/bottleneck_trees/log/bottleneck_{b}.trees"
            slim_command= f'''
                    {params.slim_executable} \
                    -d recombination_rate={params.recombination_rate}\
                    -d population_size={params.population_size}\
                    -d sequence_length={params.sequence_length}\
                    -d bottleneck_intensity={b}\
                    {input_unique} > {output_file2}
                '''
            print(f"Running command: {slim_command}")
            jobs.append(slim_command)
            i=i+1
            slurm_script_template="workflow/slurm_slim.sh"
            slurm_script_path=f"output/output_bottleneck/temp_sbtach/sbatch_{b}.sh"
            with open(slurm_script_template, "r") as slurm_template_file:
                slurm_script_content = slurm_template_file.read()
                slurm_script_content = slurm_script_content.replace("{SLIM_COMMAND}", slim_command)
            with open(slurm_script_path, "w") as slurm_script_file:
                slurm_script_file.write(slurm_script_content)
            
            shell(f"sbatch {slurm_script_path}")

            # Wait for jobs to finish
        
        #for job in jobs:
         #shell(job)  
        check_job_status()
        # Clean up temporary directories
        shell("rm -rf output/output_bottleneck/temp_sbtach")
        shell("rm -rf temp/slim")

        shell("wait")
rule pyslim:
    input:
        expand("output/output_bottleneck/bottleneck_trees/bottleneck_{coef}.trees",coef=bottleneck_coeffecients),
        "output/output_bottleneck/bottleneck_coeffecient.txt"
       
       
    output:
        expand("output/output_bottleneck/bottleneck_txt/bottleneck_{coef}.txt", coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/fasta/bottleneck_{coef}.fasta",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/vcf/bottleneck_{coef}.vcf",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/arrays/array_data_{coef}.txt",coef=bottleneck_coeffecients),
        "output/output_bottleneck/meta_data/meta_Stats.tab"
    params:
        sample_size = factors["keep_individual"],
        sequence_length = factors["sequence_length"],
        mutation_rate = factors["mutation_rate"],
        recombination_rate = factors["recombination_rate"],
        N = factors["population_size"]
    run:
       shell("mkdir -p output/output_bottleneck/plots")
       shell("mkdir -p output/output_bottleneck/temp_output")
       shell("mkdir -p output/output_bottleneck/bottleneck_txt")
       shell("mkdir -p output/output_bottleneck/fasta")
       shell("mkdir -p output/output_bottleneck/vcf")
       shell("mkdir -p output/output_bottleneck/meta_file")
       shell("mkdir -p output/output_bottleneck/arrays")
       meta_file_statistics = "output/output_bottleneck/meta_data/meta_Stats.tab"
       shell("echo 'fasta_file\tbottleneck_intensity\tTajimas_D\tTajima_pi\tnum_of_mutation' > {meta_file_statistics}")
       for b in bottleneck_coeffecients:
            
       # Execute the Jupyter Notebook using Papermill 
            input_nb = "workflow/simulate_bottleneck.ipynb"
            output_nb = f"output/output_bottleneck/temp_output/pyslim_{b}.ipynb"
            shell('''
                  papermill {input_nb} {output_nb}\
                  -p sample_size {params.sample_size}\
                  -p sequence_length {params.sequence_length}\
                  -p mutation_rate {params.mutation_rate}\
                  -p recombination_rate {params.recombination_rate}\
                  -p bottleneck_intensity {b}\
                  -p N {params.N} \
                  --engine profiling
                  ''')

rule snps_gathering:
    input:
        expand("output/output_bottleneck/fasta/bottleneck_{coef}.fasta",coef=bottleneck_coeffecients)
    
    output:
        expand("output/output_bottleneck/ancestral_sequence/ancestral_{coef}.fasta",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/matrix/matrix_{coef}.txt",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/images/image_{coef}.png",coef=bottleneck_coeffecients),
        expand("output/output_bottleneck/h_format/h_{coef}.csv",coef=bottleneck_coeffecients),
        "output/output_bottleneck/meta_data/meta_images.tab"
    
    run:
       
       shell("mkdir -p output/output_bottleneck/snps_temp_out")
       shell("mkdir -p output/output_bottleneck/snps")
       shell("mkdir -p output/output_bottleneck/ancestral_Sequence")
       shell("mkdir -p output/output_bottleneck/matrix")
       shell("mkdir -p output/output_bottleneck/images")
       shell("mkdir -p output/output_bottleneck/h_format")
       meta_image = "output/output_bottleneck/meta_data/meta_images.tab"
       shell("mkdir -p output/output_bottleneck/temp_sbatch_snp")
       input_nb2 = "workflow/snps_gathering_bottleneck.ipynb"
       shell("echo 'bottleneck_intensity\tsnps_file\tmatrix_image_file\tancestral_seq\tsnps_image' > {meta_image}")

       for i in bottleneck_coeffecients:
             input_nb2 = "workflow/snps_gathering_bottleneck.ipynb"
             output_nb2 = f"output/output_bottleneck/snps_temp_out/snps_{i}.ipynb"
             snp_command=f"papermill {input_nb2} {output_nb2} -p intensity {i} --engine profiling"
             slurm_script_template="workflow/slurm_snp.sh"
             slurm_script_path=f"output/output_bottleneck/temp_sbatch_snp/sbatch_{i}.sh"
             with open(slurm_script_template, "r") as slurm_template_file:
                 slurm_script_content = slurm_template_file.read()
                 slurm_script_content = slurm_script_content.replace("{SNP_COMMAND}", snp_command)
             with open(slurm_script_path, "w") as slurm_script_file:
                 slurm_script_file.write(slurm_script_content)
             shell(f"sbatch {slurm_script_path}")
       check_job_status()
       shell("rm -rf output/output_bottleneck/temp_sbtach_snp")
       shell("rm -rf output/output_bottleneck/snps_temp_out")
       shell("rm -rf output/output_bottleneck/temp_output")
       shell("rm -rf output/output_bottleneck/snps")

rule h_scan:
    input:
        expand("output/output_bottleneck/h_format/h_{coef}.csv",coef=bottleneck_coeffecients)
    output:
        expand("output/output_bottleneck/h_result/h_{coef}.txt",coef=bottleneck_coeffecients),
        "output/output_bottleneck/meta_data/metadata_h.tab"
    
    run:
        shell("mkdir -p output/output_bottleneck/h_result")
        metadata_file="output/output_bottleneck/meta_data/metadata_h.tab"
        shell(f"echo 'output_file\tbottleneck_intensity\taverage_h' > {metadata_file}")
    
        for i in bottleneck_coeffecients:

            input_file=f"output/output_bottleneck/h_format/h_{i}.csv"
            output=f"output/output_bottleneck/h_result/h_{i}.txt"

            shell('''
            workflow/software/H-scan -i {input_file}\
            -l 45000 -r 55000\
            -d 0 > {output}
            awk '{{ sum += $2 }} END {{ if (NR > 0) print "{output}\t{i}\t" sum / NR }}' {output} >> {metadata_file}
            ''')

rule meta_file_combining:
    input:
        "output/output_bottleneck/meta_data/meta_Stats.tab",
        "output/output_bottleneck/meta_data/meta_images.tab",
        "output/output_bottleneck/meta_data/metadata_h.tab"
    output:
        "output/output_bottleneck/meta_file.tab"
    run:
        sorted_Stats ="output/output_bottleneck/meta_data/meta_Stats_sorted.tab"
        sorted_image="output/output_bottleneck/meta_data/meta_images_sorted.tab"
        sorted_metadata_h="output/output_bottleneck/meta_data/metadata_h_sorted.tab"
        storing_file="output/output_bottleneck/meta_data/temp_meta_file.tab"
        shell('''
        # Sorting files
        (head -n 1 {input[1]} && tail -n +2 {input[1]} | sort -t$'\t' -k1,1) > {sorted_image}
        (head -n 1 {input[0]} && tail -n +2 {input[0]} | sort -t$'\t' -k2,2) > {sorted_Stats}
        (head -n 1 {input[2]} && tail -n +2 {input[2]} | sort -t$'\t' -k2,2) > {sorted_metadata_h}
        # combining_files
        join -t$'\t' -1 2 -2 1 {sorted_Stats} {sorted_image} > {storing_file} 
        join -t$'\t' -1 1 -2 2 {storing_file} {sorted_metadata_h} > {output[0]}
        rm {storing_file}
        ''')

rule scp:
    input:
       "output/output_bottleneck/meta_file.tab",
       expand("output/output_bottleneck/images/image_{coef}.png",coef=bottleneck_coeffecients),
       expand("output/output_bottleneck/bottleneck_txt/bottleneck_{coef}.txt", coef=bottleneck_coeffecients),
       expand("output/output_bottleneck/matrix/matrix_{coef}.txt", coef=bottleneck_coeffecients),
       expand("output/output_bottleneck/temp_slim/bottleneck_{coef}.slim",coef=bottleneck_coeffecients)
    output:
       f"output/output_bottleneck/final_page_{config['batch_size']}.txt"
    run:
       shell(f"cp -r {input[0]} output/output_bottleneck/meta_file_{config['batch_size']}.tab ")
       shell(f"scp -r output/output_bottleneck/meta_file_{config['batch_size']}.tab jaskaran@peru:/home/jaskaran/data_bottleneck1/meta_file")
       shell(f"cp -r output/output_bottleneck/images output/output_bottleneck/images_{config['batch_size']} ")
       shell(f"scp -r  output/output_bottleneck/images_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_bottleneck1/images")
       shell(f"cp -r output/output_bottleneck/bottleneck_txt output/output_bottleneck/bottleneck_txt_{config['batch_size']} ")
       shell(f"scp -r output/output_bottleneck/bottleneck_txt_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_bottleneck1/txt_file")
       shell(f"cp -r output/output_bottleneck/matrix output/output_bottleneck/matrix_{config['batch_size']}")
       shell(f"scp -r output/output_bottleneck/matrix_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_bottleneck1/matrix")
       shell(f"cp -r output/output_bottleneck/plots output/output_bottleneck/plots_{config['batch_size']}")
       shell(f"scp -r output/output_bottleneck/plots_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_bottleneck1/plots")
       shell(f"cp -r output/output_bottleneck/temp_slim output/output_bottleneck/temp_slim_{config['batch_size']}")
       shell(f"scp -r output/output_bottleneck/temp_slim_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_bottleneck1/temp_slim")
       shell(f"cp -r output/output_bottleneck/arrays output/output_bottleneck/arrays_{config['batch_size']}")
       shell(f"scp -r output/output_bottleneck/arrays_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_bottleneck1/arrays")
       shell(f"echo 'the transfer of the files is done' > {output[0]} ")
       time.sleep(120)  

            
    
    
