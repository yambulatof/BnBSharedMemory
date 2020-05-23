# OpenMP BnB interval solver

Scripts for running and creating statistics bnbshmem algorithms.

**Usage:**

    python3 run_all_stats.py num_of_runs run_hartman6 run_cluster2d2 output_folder

**Example:**
    
    python3 run_all_stats.py 100 1 1 results

Options:

Parameter | Description
------------ | -------------
num_of_runs | number of runs for every algorithm on every test
run_hartman6 | flag for enabing Hartman6 function tests
run_cluster2d2 | flag for enabing Cluster2D2 function tests
output_folder | folder to store results
