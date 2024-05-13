configfile : "workflow/config_selection.yaml"
factors = config["factors"]


rule all:
    input:
         "output/output_selection/selection_coeffecient_meta.txt",

rule selection_coefficient_generation:
    output:
         "output/output_selection/selection_coeffecient_meta.txt"
    params:
           lowest_s=factors["lowest_s"],
           highest_s=factors["highest_s"],
           num_of_data=factors["num_of_data"]
    
    run:
        input_nb3="workflow/selection_coeff.ipynb"
        output_nb3="output/output_selection/sel_coeff_nb.ipynb"
        shell('''
               papermill {input_nb3} {output_nb3} \
                        -p lowest_s {params.lowest_s} \
                        -p highest_s {params.highest_s} \
                        -p num_of_data {params.num_of_data} 
              ''')


