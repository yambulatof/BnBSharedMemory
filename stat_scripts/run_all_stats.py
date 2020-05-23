import os
import sys
import run_stat_utils
import datetime

runs = '1'
run_hartman6 = False
run_cluster2d2 = False
output_dir = ''
if len(sys.argv) == 4 or len(sys.argv) == 5:
    runs = sys.argv[1]
    run_hartman6 = sys.argv[2] == '1'
    run_cluster2d2 = sys.argv[3] == '1'
    if len(sys.argv) == 5:
        output_dir = sys.argv[4]
else:
    print('Usage: python3 ./run_all_stats num_of_runs run_hartman6 run_cluster2d2 output_folder')
    sys.exit(1)

TEST_ARGS = {
    "Hartman 6 function": ["uknrec", "0.02", "2000000", "16"],
    "Cluster2D2 function": ["uknrec", "0.2", "10000000", "16"],
}

ALGORITHM_ARGS = {
    "bnbatomic.exe": ["1000", "statonly"],
    "bnbomp.exe": ["statonly"],
    "lpamigo.exe": ["statonly"],
    "gpamigo.exe": ["statonly"],
}

currentDT = datetime.datetime.now()
if output_dir == '':
    dir = "./results_{}".format(currentDT.strftime("%m_%d_%H_%M_%S"))
else:
    dir = output_dir

if not os.path.exists(dir):
    os.makedirs(dir)

for algo_name in ALGORITHM_ARGS.keys():
    for test_name in TEST_ARGS.keys():
        if ('Hartman' in test_name) and not run_hartman6:
            continue
        if ('Cluster2D2' in test_name) and not run_cluster2d2:
            continue
        all_args = [algo_name, runs, test_name] + TEST_ARGS[test_name] + ALGORITHM_ARGS[algo_name]
        run_stat_utils.runcmd(dir, all_args)
