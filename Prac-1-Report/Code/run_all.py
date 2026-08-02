import os
import subprocess

# Define the directory containing your Python files
# Use '.' for the current directory or specify a path
target_directory = '.'

for filename in os.listdir(target_directory):
    if filename.endswith(".py") and filename != "run_all.py":
        filepath = os.path.join(target_directory, filename)
        print(f"Running {filepath}...")
        try:
            # Use subprocess.run for better control over execution
            subprocess.run(["python3", filepath], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error running {filepath}: {e}")
        print("-" * 30)