# snakemake file for simulating the selection
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

configfile : "workflow/config_selection.yaml"
factors = config["factors"]

#rule debug:
    #shell:
       #"conda info"

with open("output/output_selection/selection_coeffecient.txt") as f:
    global selection_coefficients
    selection_coefficients = [line.strip() for line in f]
rule all:
    input:
         "output/output_selection/dag.png",
         expand("output/output_selection/selection_txt/selection_{coef}.txt", coef=selection_coefficients),
         expand("output/output_selection/fasta/selection_{coef}.fasta",coef=selection_coefficients),
         expand("output/output_selection/vcf/selection_{coef}.vcf",coef=selection_coefficients),
         expand("output/output_selection/selection_trees/selection_{coef}.trees", coef=selection_coefficients),
         expand("output/output_selection/ancestral_sequence/ancestral_{coef}.fasta",coef=selection_coefficients),
         expand("output/output_selection/images/image_{coef}.png",coef=selection_coefficients),
         expand("output/output_selection/h_format/h_{coef}.csv",coef=selection_coefficients),
         expand("output/output_selection/h_result/h_{coef}.txt",coef=selection_coefficients),
         expand("output/output_selection/temp_slim/selection_{coef}.slim",coef=selection_coefficients),
         "output/output_selection/meta_data/meta_Stats.tab",
         "output/output_selection/meta_data/meta_images.tab",
         "output/output_selection/meta_data/metadata_h.tab",
         "output/output_selection/meta_file.tab",
         f"output/output_selection/final_page_{config['batch_size']}.txt"
         #"output/output_selection/snps.fasta",

rule dag:
    output:
        "output/output_selection/dag.png"
    run:
        shell("mkdir -p output/output_selection")
        shell("snakemake --dag -s workflow/simulate_selection.smk | dot -Tpng > output/output_selection/dag.png")


rule slim:
    input:
        "workflow/selection.slim",
        "output/output_selection/selection_coeffecient.txt"
    output:
        expand("output/output_selection/selection_trees/selection_{coef}.trees",coef=selection_coefficients),
        expand("output/output_selection/temp_slim/selection_{coef}.slim",coef=selection_coefficients)
    params:
        slim_executable="/dss/dsshome1/09/ra78pec/mambaforge/envs/snakemake/bin/slim",
        # Add the location of your slim executable here (use "wheris slim")
        mutation_rate=factors["mutation_rate"],
        recombination_rate=factors["recombination_rate"],
        population_size=factors["population_size"],
        sequence_length=factors["sequence_length"],
        dominance_coeffecient=factors["dominance_coeffecient"],
        when_selection=factors["when_selection"],
        half_of_the_sequence=factors["half_of_the_sequence"],
        stop_generation=factors["when_selection"]
    run:
        # Iterate through selection coefficients 
        shell("mkdir -p output/output_selection/selection_trees/log")
        shell("mkdir -p output/output_selection/temp_slim")
        shell("mkdir -p output/output_selection/temp_sbtach")
        shell("mkdir -p temp/slim")
        shell("mkdir -p output/output_selection/arrays")
        i=1
        jobs = []
        for s in selection_coefficients:           
            input_unique=f"output/output_selection/temp_slim/selection_{s}.slim"
            shell("touch {input_unique}")
            random_location = random.randint(1,100000)
            # Update the stop_generation value in the script
            with open(input[0], "r") as file:
              script_content = file.read()
              script_content = script_content.replace("stop_generation", f"{params.stop_generation}")
              script_content = script_content.replace("sg1", f"{params.stop_generation-1}")
              script_content = script_content.replace("random_location", f"{random_location}")
            with open(input_unique, "w") as file:
              file.write(script_content)
            output_file2 =f"output/output_selection/selection_trees/log/selection_{s}.trees"
            seed = 1234+i
            slim_command= f'''
                    {params.slim_executable} \
                    -d mutation_rate={params.mutation_rate}\
                    -d recombination_rate={params.recombination_rate}\
                    -d population_size={params.population_size}\
                    -d sequence_length={params.sequence_length}\
                    -d selection_coeffecient={s}\
                    -d dominance_coeffecient={params.dominance_coeffecient}\
                    -d when_selection={params.when_selection}\
                    {input_unique} > {output_file2}
                '''
            print(f"Running command: {slim_command}")
            jobs.append(slim_command)
            i=i+1
            slurm_script_template="workflow/slurm_slim.sh"
            slurm_script_path=f"output/output_selection/temp_sbtach/sbatch_{s}.sh"
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
        shell("rm -rf output/output_selection/temp_sbtach")
        shell("rm -rf temp/slim")
        shell("wait")
        
rule pyslim:
    input:
        expand("output/output_selection/selection_trees/selection_{coef}.trees",coef=selection_coefficients),
        "output/output_selection/selection_coeffecient.txt"
       
       
    output:
        expand("output/output_selection/selection_txt/selection_{coef}.txt", coef=selection_coefficients),
        expand("output/output_selection/fasta/selection_{coef}.fasta",coef=selection_coefficients),
        expand("output/output_selection/vcf/selection_{coef}.vcf",coef=selection_coefficients),
        expand("output/output_selection/arrays/array_data_{coef}.txt",coef=selection_coefficients),
        "output/output_selection/meta_data/meta_Stats.tab"
    params:
        sample_size = factors["keep_individual"],
        sequence_length = factors["sequence_length"],
        mutation_rate = factors["mutation_rate"],
        recombination_rate = factors["recombination_rate"],
        N = factors["population_size"]
    run:
       shell("mkdir -p output/output_selection/plots")
       shell("mkdir -p output/output_selection/temp_output")
       shell("mkdir -p output/output_selection/selection_txt")
       shell("mkdir -p output/output_selection/fasta")
       shell("mkdir -p output/output_selection/vcf")
       shell("mkdir -p output/output_selection/meta_file")
       meta_file_statistics = "output/output_selection/meta_data/meta_Stats.tab"
       shell("echo 'fasta_file\tselection_coefficient\tTajimas_D\tTajima_pi\tnum_of_mutation' > {meta_file_statistics}")
       for s in selection_coefficients:
            
       # Execute the Jupyter Notebook using Papermill 
            input_nb = "workflow/simulate_selection.ipynb"
            output_nb = f"output/output_selection/temp_output/pylim_{s}.ipynb"
            shell('''
                  papermill {input_nb} {output_nb}\
                  -p sample_size {params.sample_size}\
                  -p sequence_length {params.sequence_length}\
                  -p mutation_rate {params.mutation_rate}\
                  -p recombination_rate {params.recombination_rate}\
                  -p selection_coefficient {s}\
                  -p N {params.N} \
                  --engine profiling
                  ''')

rule snps:
    input:
       expand("output/output_selection/fasta/selection_{coef}.fasta",coef=selection_coefficients)
    output:
       expand("output/output_selection/ancestral_sequence/ancestral_{coef}.fasta",coef=selection_coefficients),
       expand("output/output_selection/images/image_{coef}.png",coef=selection_coefficients),
       expand("output/output_selection/h_format/h_{coef}.csv",coef=selection_coefficients),
       expand("output/output_selection/matrix/matrix_{coef}.txt",coef=selection_coefficients),
       "output/output_selection/meta_data/meta_images.tab"

    run:
        shell("mkdir -p output/output_selection/snps_temp_out")
        shell("mkdir -p output/output_selection/snps")
        shell("mkdir -p output/output_selection/ancestral_sequence")
        shell("mkdir -p output/output_selection/images")
        shell("mkdir -p output/output_selection/matrix")
        shell("mkdir -p output/output_selection/h_format")
        shell("mkdir -p temp/snp")
        meta_image = "output/output_selection/meta_data/meta_images.tab"
        shell("mkdir -p output/output_selection/temp_sbatch_snp")
        shell("echo 'selection_coefficient\tsnps_file\tmatrix_image_file\tancestral_seq\tsnps_image' > {meta_image}")
        for s in selection_coefficients:
            input_nb2 = "workflow/snps_gathering.ipynb"
            output_nb2 = f"output/output_selection/snps_temp_out/snps_{s}.ipynb"
            snp_command=f"papermill {input_nb2} {output_nb2} -p selection_coefficient {s} --engine profiling"
            slurm_script_template="workflow/slurm_snp.sh"
            slurm_script_path=f"output/output_selection/temp_sbatch_snp/sbatch_{s}.sh"
            with open(slurm_script_template, "r") as slurm_template_file:
                slurm_script_content = slurm_template_file.read()
                slurm_script_content = slurm_script_content.replace("{SNP_COMMAND}", snp_command)
            with open(slurm_script_path, "w") as slurm_script_file:
                slurm_script_file.write(slurm_script_content)
            shell(f"sbatch {slurm_script_path}")
        check_job_status()
        shell("rm -rf output/output_selection/temp_sbtach_snp")
        shell("rm -rf output/output_selection/snps_temp_out")
        shell("rm -rf output/output_selection/temp_output")
        shell("rm -rf output/output_selection/snps")


rule h_scan:
    input:
        expand("output/output_selection/h_format/h_{coef}.csv",coef=selection_coefficients)
    output:
        expand("output/output_selection/h_result/h_{coef}.txt",coef=selection_coefficients),
        "output/output_selection/meta_data/metadata_h.tab"
    
    run:
        shell("mkdir -p output/output_selection/h_result")
        metadata_file="output/output_selection/meta_data/metadata_h.tab"
        shell(f"echo 'output_file\tselection_coefficient\taverage_h' > {metadata_file}")
    
        for s in selection_coefficients:

            input_file=f"output/output_selection/h_format/h_{s}.csv"
            output=f"output/output_selection/h_result/h_{s}.txt"

            shell('''
            workflow/software/H-scan -i {input_file}\
            -l 45000 -r 55000\
            -d 0 > {output}
            awk '{{ sum += $2 }} END {{ if (NR > 0) print "{output}\t{s}\t" sum / NR }}' {output} >> {metadata_file}
            ''')
rule meta_file_combining:
    input:
        "output/output_selection/meta_data/meta_Stats.tab",
        "output/output_selection/meta_data/meta_images.tab",
        "output/output_selection/meta_data/metadata_h.tab"
    output:
        "output/output_selection/meta_file.tab"
    run:
        sorted_Stats ="output/output_selection/meta_data/meta_Stats_sorted.tab"
        sorted_image = "output/output_selection/meta_data/meta_images_sorted.tab"
        sorted_metadata_h="output/output_selection/meta_data/metadata_h_sorted.tab"
        storing_file="output/output_selection/meta_data/temp_meta_file.tab"
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
       "output/output_selection/meta_file.tab",
       expand("output/output_selection/images/image_{coef}.png",coef=selection_coefficients),
       expand("output/output_selection/selection_txt/selection_{coef}.txt", coef=selection_coefficients),
       expand("output/output_selection/matrix/matrix_{coef}.txt", coef=selection_coefficients),
       expand("output/output_selection/temp_slim/selection_{coef}.slim",coef=selection_coefficients)
    output:
       f"output/output_selection/final_page_{config['batch_size']}.txt"
    run:
       shell(f"cp -r {input[0]} output/output_selection/meta_file_{config['batch_size']}.tab ")
       shell(f"scp -r output/output_selection/meta_file_{config['batch_size']}.tab jaskaran@peru:/home/jaskaran/data_selection/meta_file")
       shell(f"cp -r output/output_selection/images output/output_selection/images_{config['batch_size']} ")
       shell(f"scp -r  output/output_selection/images_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_selection/images")
       shell(f"cp -r output/output_selection/selection_txt output/output_selection/selection_txt_{config['batch_size']} ")
       shell(f"scp -r output/output_selection/selection_txt_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_selection/txt_file")
       shell(f"cp -r output/output_selection/matrix output/output_selection/matrix_{config['batch_size']}")
       shell(f"scp -r output/output_selection/matrix_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_selection/matrix")
       shell(f"cp -r output/output_selection/plots output/output_selection/plots_{config['batch_size']}")
       shell(f"scp -r output/output_selection/plots_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_selection/plots")
       shell(f"cp -r output/output_selection/temp_slim output/output_selection/temp_slim_{config['batch_size']}")
       shell(f"scp -r output/output_selection/temp_slim_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_selection/temp_slim")
       shell(f"cp -r output/output_selection/arrays output/output_selection/arrays_{config['batch_size']}")
       shell(f"scp -r output/output_selection/arrays_{config['batch_size']} jaskaran@peru:/home/jaskaran/data_selection/arrays")
       shell(f"echo 'the transfer of the files is done' > {output[0]} ")
       
       time.sleep(120)











        
     
           