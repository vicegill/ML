#!/bin/bash
#SBATCH --get-user-env
#SBATCH --clusters=biohpc_gen
#SBATCH --partition=biohpc_gen_production
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=10
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4000mb
#SBATCH --time=72:00:00
#SBATCH -J slim_run
#SBATCH --output=slim_run_%j.out
#SBATCH --error=slim_run_%j.err

snakemake -s workflow/simulate_selection.smk \
          --jobs 50 \
          --rerun-incomplete \