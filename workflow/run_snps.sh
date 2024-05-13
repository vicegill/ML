#!/bin/bash

for s in $(cat /Users/vicegill/Documents/Master_thesis_meta/Master_thesis/thesis_project_jaskaran/output/output_selection/selection_coeffecient.txt); do
  papermill workflow/snps_gathering.ipynb output/output_selection/snps_temp_out/snps_${s}.ipynb -p selection_coefficient $s --engine profiling
done
