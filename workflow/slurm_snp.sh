#!/bin/bash
#SBATCH --get-user-env
#SBATCH --clusters=biohpc_gen
#SBATCH --partition=biohpc_gen_normal
#SBATCH --mem-per-cpu=4000mb
#SBATCH --time=1:00:00
#SBATCH -J snp
#SBATCH --output=temp/snp/snp_%j.out
#SBATCH --error=temp/snp/snp_%j.err

{SNP_COMMAND}