#!/usr/bin/env python3

import os
import pickle
import signal

build_dir = os.path.join(os.path.dirname(__file__), '..', 'build')

vm_dict_file = f"{build_dir}/vm_dict_file"
vm_dict = {}

if os.path.isfile(vm_dict_file):
    with open(vm_dict_file, 'rb') as f:
        data = f.read()
        if data:
            vm_dict = pickle.loads(data)

for vm in vm_dict:
    pid = vm_dict[vm][0]
    name = vm_dict[vm][1][0]
    print(f"Killing {name} process with pid {pid}", end ="... ")
    try:
        os.kill(pid, signal.SIGKILL)
        print("OK")
    except ProcessLookupError:
        print("Not found")
