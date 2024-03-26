import sys

total_source_vms = int(sys.argv[1])
const_dest_vms = int(sys.argv[2])

def avg_multi_source_multi_dest(source_vms):
    avg = 0
    count = 0
    for vm_index in range(1, source_vms+1):
        f = open(f"ping_{source_vms}x{const_dest_vms}_{vm_index}", "r")
        line = f.readline()
        line = line.strip()

        if line:
            try:
                avg += float(line)
                count += 1
            except ValueError:
                continue

    f.close()

    if count > 0.97 * source_vms:
        return avg/count
    return 0



result = open(f"constDest_{const_dest_vms}", "w")

for source_vm_index in range(1, total_source_vms+1):
    res = avg_multi_source_multi_dest(source_vm_index)
    result.write(str(res)+"\t")

result.close()