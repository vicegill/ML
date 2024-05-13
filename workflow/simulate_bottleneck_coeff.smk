configfile : "workflow/config_bottleneck.yaml"
factors = config["factors"]


rule all:
    input:
         "output/output_bottleneck/bottleneck_coeffecient_meta.txt"

rule selection_coefficient_generation:
    output:
         "output/output_bottleneck/bottleneck_coeffecient_meta.txt"
    params:
           lowest_i=factors["lowest_i"],
           highest_i=factors["highest_i"],
           num_of_data=factors["num_of_data"]
    run:
        input_nb3="workflow/bottleneck_coeff.ipynb"
        output_nb3="output/output_bottleneck/sel_coeff_nb.ipynb"
        shell('''
               papermill {input_nb3} {output_nb3} \
                        -p lowest_i {params.lowest_i} \
                        -p highest_i {params.highest_i} \
                        -p num_of_data {params.num_of_data} 
              ''')