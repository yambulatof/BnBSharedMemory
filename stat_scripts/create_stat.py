import os
import subprocess
import sys
import csv
import statistics

def print_csv_row(row):
    print(','.join(row))

def makeStat(name, serl):
    print(name, " mean: ", statistics.mean(serl))
    print(name, " stddev: ", statistics.stdev(serl))
    print(name, " min: ", min(serl))
    print(name, " max: ", max(serl))
    print(name, " maxmindev: ", mmdev(serl))


output = subprocess.run(sys.argv[1:],stdout=subprocess.PIPE)
sout = output.stdout.decode()
p = sout.find('Statistics:')
ls = sout[p:].splitlines()[1:]
print('Time, Steps, TimePerStep, Error')
for row in ls:
    print(row)
#cls = ls[1:]

#rd = csv.reader(cls)
#timel = []
#stepl = []
#tpsl = []
#print('Time, Steps, TimePerStep, Error')
#for row in rd:
#    print_csv_row(row)
#    timel.append(float(row[0]))
#    stepl.append(float(row[1]))
#    tpsl.append(float(row[2]))
    #print(row)

#makeStat("Time", timel)
#makeStat("Steps", stepl)
#makeStat("TPS", tpsl)
#print(output.stdout.decode())
#process = os.popen(sys.argv[1:])
#strout = process.read()
#process.close()
#print(strout)
