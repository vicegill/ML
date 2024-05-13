import random  # Import the random module for generating random numbers
import subprocess  # Import the subprocess module for running shell commands
import time  # Import the time module for time-related functions

# Print header information
print('''CHECK 
      written by: Jaskaran S. Gill
      Lab: Dirk Metzler Lab

      ''')

# Function to check job status in the cluster
def check_job_status(cluster_name, user_name, time_duration):
    while True:
        # Run 'squeue' command to get job status for the specified cluster and user
        result = subprocess.run(["squeue", "--cluster", cluster_name, "-u", user_name], capture_output=True, text=True)
        output = result.stdout.strip().split("\n")  # Split the output into lines
        
        job_lines = output[2:]  # Extract lines containing job information
        for i in job_lines:
            print(i)  # Print each line of job information
        
        if len(job_lines) == 0:
            print("No jobs in the queue. 😀")  # If no jobs found, print a message and break the loop
            break
        
        print("Jobs still in the queue. Waiting... 🐥🐤⏰⏰⏰⏰ ")  # If jobs found, print a waiting message
        
        time.sleep(time_duration)  # Wait for the specified time duration before checking again

# Prompt for cluster name, username, and time duration
cluster_name = input("what's the name of the cluster: ")
user_name = input("what's the username of the individual: ")
time_duration = int(input("After what Interval u want to see the response (in sec): "))

# Call the check_job_status function with the provided parameters
check_job_status(cluster_name, user_name, time_duration)
