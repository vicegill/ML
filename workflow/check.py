import random
import subprocess
import time

print('''CHECK 
      written by: Jaskaran S. Gill
      Lab: Dirk Metzler Lab

      ''')

def check_job_status(cluster_name,user_name,time_duration):
    while True:
        result = subprocess.run(["squeue","--cluster",cluster_name,"-u",user_name],capture_output =True , text= True)
        output = result.stdout.strip().split("\n")

        job_lines = output[2:]
        for i in job_lines:
            print(i)
        if len(job_lines) == 0:
            print("No jobs in the queue. 😀")
            break
        
        print("Jobs still in the queue. Waiting... 🐥🐤⏰⏰⏰⏰ ")
        
        time.sleep(time_duration)
cluster_name = input("what's the name of the cluster: ",)
user_name = input("what's the username of the individual: ",)
time_duration = int(input("After what Interval u want to see the response (in sec): ",))
check_job_status(cluster_name,user_name,time_duration)