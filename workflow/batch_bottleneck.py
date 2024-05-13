import sys  # Import sys module to access system-specific parameters and functions
import subprocess  # Import subprocess module to spawn new processes, connect to their input/output/error pipes, and obtain their return codes
import os  # Import os module to interact with the operating system
import shutil  # Import shutil module to perform file operations
import time  # Import time module to work with time-related functions

# Set environment variable to ensure Python output is unbuffered
os.environ['PYTHONUNBUFFERED'] = '1'

# Print current working directory
print(os.getcwd())

# Get batch size from command-line arguments
batch_size = int(sys.argv[1])

# Read bottleneck coefficients from file
k = []
with open("output/output_bottleneck/bottleneck_coeffecient_meta.txt", "r") as file:
    for line in file:
        k.append(line.strip())

# Process batches of bottleneck coefficients
for i in range(2700, len(k), batch_size):
    # Select batch
    batch = k[i:i+batch_size]
    
    # Write batch to file
    with open("output/output_bottleneck/bottleneck_coeffecient.txt", "w") as file:
        for item in batch:
            file.write(item + "\n")
    
    try:
        # Execute Snakemake command with specified parameters
        result = subprocess.Popen(["snakemake", "-s", "workflow/simulate_bottleneck.smk", "--cores", "10", "--rerun-incomplete", "--config", f"batch_size={i}"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        
        # Print output from Snakemake command
        for line in result.stdout:
            print(line.strip())
        
        result.wait()  # Wait for the subprocess to finish
    except subprocess.CalledProcessError as e:
        # Handle the error by printing the error message
        print("Error executing Snakemake command:", e)
    
    time.sleep(60)  # Wait for 60 seconds

    # Directories to be removed
    dirs_to_remove = [
        "output/output_bottleneck/ancestral_sequence",
        "output/output_bottleneck/fasta",
        # Add other directories here...
    ]

    # Remove directories
    for directory in dirs_to_remove:
        shutil.rmtree(directory, ignore_errors=True)  # Remove directory and its contents, ignoring errors

    time.sleep(60)  # Wait for 60 seconds
