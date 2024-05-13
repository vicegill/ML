#!/bin/bash
#SBATCH --get-user-env
#SBATCH --clusters=biohpc_gen
#SBATCH --partition=biohpc_gen_normal
#SBATCH --mem-per-cpu=4000mb
#SBATCH --time=1:00:00
#SBATCH -J slim_run
#SBATCH --output=temp/slim/slim_run_%j.out
#SBATCH --error=temp/slim/slim_run_%j.err


{SLIM_COMMAND}