import os

def get_test_short_name(full_name):
    return full_name.lower().replace(' ', '')[:-8]

def runcmd(folder, cmd):
    command = ""
    fname = ""
    test_name = get_test_short_name(cmd[2])
    algo_name = cmd[0][:-4]
    if not os.path.exists('{}/{}'.format(folder, algo_name)):
        os.makedirs('{}/{}'.format(folder, algo_name))
    file_name = '{}/{}/data_{}'.format(folder, algo_name, test_name)
    for arg in cmd:
        if ' ' in arg:
            command += ("\"" + arg + "\"")
        else:
            command += arg
        command += " "
    command += "> "
    command += file_name + '.full_output'
    command = "./" + command
    print(command)
    os.system(command)
    analys = "python3 ./create_stat.py cat " + file_name + '.full_output' + " > " + file_name + '.csv'
    print(analys)
    os.system(analys)
