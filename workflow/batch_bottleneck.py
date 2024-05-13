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
with open("output/output_bottleneck/bottleneck_coeffecient_meta.txt","r") as file:
    for line in file:
         k.append(line.strip())
for i in range(2700,len(k),batch_size):
    batch = k[i:i+batch_size]
    with open("output/output_bottleneck/bottleneck_coeffecient.txt","w") as file:
          for item in batch:
            file.write(item + "\n")
    try:
        result = subprocess.Popen(["snakemake", "-s", "workflow/simulate_bottleneck.smk", "--cores", "10","--rerun-incomplete","--config", f"batch_size={i}"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        for line in result.stdout:
               print(line.strip())
        result.wait()
    except subprocess.CalledProcessError as e:
        # Handle the error by printing the error message
        print("Error executing Snakemake command:", e)
    time.sleep(60)
    dirs_to_remove = [
        "output/output_bottleneck/ancestral_sequence",
        "output/output_bottleneck/fasta",
        "output/output_bottleneck/h_format",
        "output/output_bottleneck/h_result",
        "output/output_bottleneck/plots",
        "output/output_bottleneck/vcf",
        "output/output_bottleneck/matrix",
        "output/output_bottleneck/meta_file.tab",
        "output/output_bottleneck/temp_slim",
        "output/output_bottleneck/bottleneck_trees",
        "output/output_bottleneck/meta_data",
        "output/output_bottleneck/images",
        f"output/output_bottleneck/images_{i}",
        f"output/output_bottleneck/meta_file_{i}",
        f"output/output_bottleneck/matrix_{i}",
        f"output/output_bottleneck/plots_{i}",
        f"output/output_bottleneck/bottleneck_txt_{i}",
        "output/output_bottleneck/images",
        "output/output_bottleneck/temp_sbatch_snp",
        f"output/output_bottleneck/bottleneck_txt",
        f"output/output_bottleneck/temp_slim_{i}",
        f"output/output_bottleneck/arrays_{i}"
    ]
    for directory in dirs_to_remove:
        shutil.rmtree(directory, ignore_errors=True)
    time.sleep(60)