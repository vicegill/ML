import sys
import subprocess
import os
import shutil
import time
os.environ['PYTHONUNBUFFERED'] = '1'
print(os.getcwd())
batch_size = int(sys.argv[1])
#batch_size = int(input("Whats the batch size u want : ",))
k = []
with open("output/output_selection/selection_coeffecient_meta.txt","r") as file:
    for line in file:
         k.append(line.strip())
for i in range(4950,len(k),batch_size):
    batch = k[i:i+batch_size]
    with open("output/output_selection/selection_coeffecient.txt","w") as file:
          for item in batch:
            file.write(item + "\n")
    try:
        result = subprocess.Popen(["snakemake", "-s", "workflow/simulate_selection.smk", "--cores", "10","--rerun-incomplete","--config", f"batch_size={i}"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in result.stdout:
               print(line.strip())
        result.wait()
    except subprocess.CalledProcessError as e:
        # Handle the error by printing the error message
        print("Error executing Snakemake command:", e)
    time.sleep(60)
    dirs_to_remove = [
        "output/output_selection/ancestral_sequence",
        "output/output_selection/fasta",
        "output/output_selection/h_format",
        "output/output_selection/h_result",
        "output/output_selection/plots",
        "output/output_selection/vcf",
        "output/output_selection/matrix",
        "output/output_selection/meta_file.tab",
        "output/output_selection/temp_slim",
        "output/output_selection/selection_trees",
        "output/output_selection/meta_data",
        "output/output_selection/images",
        f"output/output_selection/images_{i}",
        f"output/output_selection/meta_file_{i}",
        f"output/output_selection/matrix_{i}",
        f"output/output_selection/plots_{i}",
        f"output/output_selection/selection_txt_{i}",
        "output/output_selection/images",
        "output/output_selection/temp_sbatch_snp",
        f"output/output_selection/selection_txt",
        f"output/output_selection/temp_slim_{i}",
        f"output/output_selection/arrays",
        f"output/output_selection/arrays_{i}",
    ]
    for directory in dirs_to_remove:
        shutil.rmtree(directory, ignore_errors=True)
    time.sleep(60)