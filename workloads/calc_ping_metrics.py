import sys


start = int(sys.argv[1])
end = int(sys.argv[2])
exp_no = end-1

avg = 0

for i in range(start, end):
    f = open(f"{exp_no}_ping_{i}", "r")
    line = f.readline()
    met = line.strip().split('=')
    met = met[1].split('/')
    avg += float(met[1])
    f.close()

avg = avg / (end-start)

print(avg)