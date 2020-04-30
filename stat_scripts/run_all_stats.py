import os
import run_stat_utils

runs = "600"
dir = "./results" + runs
if not os.path.exists(dir):
    os.makedirs(dir)

run_stat_utils.runcmd(dir, ["bnbatomic.exe", runs, "Hartman 6 function", "uknrec", "0.02", "1000000", "16", "1000"])
run_stat_utils.runcmd(dir, ["bnbomp.exe", runs, "Hartman 6 function", "uknrec", "0.02", "1000000", "16"])
run_stat_utils.runcmd(dir, ["lpamigo.exe", runs, "Hartman 6 function", "uknrec", "0.02", "1000000", "16"])
run_stat_utils.runcmd(dir, ["gpamigo.exe", runs, "Hartman 6 function", "uknrec", "0.02", "2000000", "16"])

#run_stat_utils.runcmd(dir, ["bnbatomic.exe", runs, "Cluster2D2 function", "uknrec", "0.2", "10000000", "16", "1000"])
#run_stat_utils.runcmd(dir, ["bnbomp.exe", runs, "Cluster2D2 function", "uknrec", "0.2", "10000000", "16"])
#run_stat_utils.runcmd(dir, ["lpamigo.exe", runs, "Cluster2D2 function", "uknrec", "0.2", "10000000", "16"])
#run_stat_utils.runcmd(dir, ["gpamigo.exe", runs, "Cluster2D2 function", "uknrec", "0.2", "10000000", "16"])
