from flask import Flask, render_template, request,redirect,url_for
import yaml
import webbrowser
import os
import time
import threading

app=Flask(__name__)

with open('workflow/config_bottleneck.yaml', 'r') as config_file:
    config_data = yaml.safe_load(config_file)
submitted_message = None
def close_webpage():
    time.sleep(10)  # Adjust the delay as needed
    os._exit(0)
@app.route('/bottleneck/', methods=['GET', 'POST'])    
@app.route("/bottleneck", methods=['GET','POST'])
def upload_parameter():
    global submitted_message
    if request.method == 'POST':
        # Update the configuration if submitted by post method
        config_data['factors']['mutation_rate'] = float(request.form.get('mutation_rate', 0.00000003))
        config_data['factors']['recombination_rate'] = float(request.form.get('recombination_rate', 0.00000000003))
        config_data['factors']['population_size']= int(request.form.get('population_size', 50000))
        config_data['factors']['keep_individual']=int(request.form.get('keep_individual',50))
        config_data['factors']['sequence_length']= int(request.form.get('sequence_length',100000))
        config_data['factors']['bottleneck_intensity']= float(request.form.get('bottleneck_intensity',0.4))
        config_data['factors']['bottleneck_point']=float(request.form.get('bottleneck_point',0.1))
        config_data['factors']['num_replicates']=int(request.form.get('num_replicates',10))
        config_data['factors']['lowest_i']=float(request.form.get('lowest_i',0.01))
        config_data['factors']['highest_i']=float(request.form.get('highest_i',1))
        config_data['factors']['num_of_data']=int(request.form.get('num_of_data',10))

        # Write the updated configuration back to config.yaml
        with open('workflow/config_selection.yaml', 'w') as config_file:
            yaml.dump(config_data, config_file)

        threading.Thread(target=close_webpage).start()   
        return redirect(url_for('submitted_page'))


    # Render the HTML template with the current parameter values
    return render_template('bottleneck.html', factors=config_data['factors'],submitted_message=submitted_message)

@app.route('/submitted')
def submitted_page():
    return render_template('submitted.html')

if __name__ == '__main__':
    # Open the web browser with the URL when the application starts
    webbrowser.open('http://127.0.0.1:5000/bottleneck')

    # Run the Flask application
    app.run(debug=True)