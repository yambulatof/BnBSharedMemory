import os
import subprocess
import sys
import csv
import statistics

def print_csv_row(row):
    print(','.join(row))

output = subprocess.run(sys.argv[1:],stdout=subprocess.PIPE)
sout = output.stdout.decode()
p = sout.find('Statistics:')
ls = sout[p:].splitlines()[1:]
print('Time, Steps, TimePerStep, Error')
for row in ls:
    print(row)
