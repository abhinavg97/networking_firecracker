import sys

num_vms = int(sys.argv[1])
avg = 0

for vm_index in range(1, num_vms+1):
    f = open(f"ping_{vm_index}", "r")
    line = f.readline()
    met = line.strip().split('=')
    met = met[1].split('/')
    avg += float(met[1])
    f.close()

avg = avg / num_vms
print(avg)