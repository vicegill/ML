from flask import Flask, render_template, request
import yaml
import webbrowser
import os

app=Flask(__name__)

with open('workflow/config_selection.yaml', 'r') as config_file:
    config_data = yaml.safe_load(config_file)


@app.route('/output', methods=['GET', 'POST'])    
def upload_parameter():
    if request.method == 'POST':
        # Update the configuration if submitted by post method
        config_data['factors']['mutation_rate'] = float(request.form.get('mutation_rate', 0.00000003))
        config_data['factors']['recombination_rate'] = float(request.form.get('recombination_rate', 0.00000000003))
        config_data['factors']['population_size']= int(request.form.get('population_size', 50000))
        config_data['factors']['keep_individual']=int(request.form.get('keep_individual',50))
        config_data['factors']['sequence_length']= int(request.form.get('sequence_length',100000))
        config_data['factors']['half_of_the_sequence']= int(request.form.get('half_of_the_sequence',49999))
        config_data['factors']['when_selection']=int(request.form.get('when_selection',4999))
        config_data['factors']['dominance_coeffecient']=float(request.form.get('dominance_coeffecient',0.5))
        config_data['factors']['lowest_s']=float(request.form.get('lowest_s',0.01))
        config_data['factors']['highest_s']=float(request.form.get('highest_s',1))
        config_data['factors']['num_of_data']=int(request.form.get('num_of_data',10))

        # Write the updated configuration back to config.yaml
        with open('workflow/config_selection.yaml', 'w') as config_file:
            yaml.dump(config_data, config_file)

    # Render the HTML template with the current parameter values
    return render_template('output.html', factors=config_data['factors'])

if __name__ == '__main__':
    # Open the web browser with the URL when the application starts
    webbrowser.open('http://127.0.0.1:5000/output')

    # Run the Flask application
    app.run(debug=True)