import subprocess
from tqdm import tqdm

def KB(val) -> int:
    return val << 10

def ipv4_to_int(ip):
    return sum([int(x) << (8 * i) for i, x in enumerate([y for y in ip.split('.')][::-1])])

def int_to_ipv4(n):
    return '.'.join([str((n >> (8 * i)) & 0xff) for i in range(3, -1, -1)])


base_ip = ipv4_to_int("20.0.0.0")
base_port = 10010
num_ips = KB(2)
num_port = 16

def __generate_flow_list() -> list:
    retval = []
    for i in range(0, num_ips):
        for j in range(0, num_port):
            ip =  int_to_ipv4(base_ip+i)
            port = base_port+j
            retval.append((ip, port))
    return retval

# clear flows
cmd = "/usr/local/bin/ovs-ofctl del-flows br0"
subprocess.run(cmd, shell=True, stdout=subprocess.PIPE)

# add flows
flow_list = __generate_flow_list()
print(f"loading {len(flow_list)} of flows...")

for (ip, port) in tqdm(flow_list):
    cmd = f"/usr/local/bin/ovs-ofctl add-flow br0 \"cookie=0,priority=40001,udp,in_port=1,nw_dst={ip},tp_dst={port},actions=move:udp_src->udp_dst,move:ip_src->ip_dst,output:in_port\""
    subprocess.run(cmd, shell=True, stdout=subprocess.PIPE)
