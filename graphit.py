
path="/Users/pasithea/results_40sec/"

x = []

yreceived = []
ysent = []
yfivenine = []
yfournine = []
ythreenine = []
ytwonine = []
yonenine = []
ysevenfive = []
yfivezero = []
ytwofive = []
yavglatency = []
ystddevlatency = []


def graphit():

	for i in range(1, 127):
		x.append(i)

		with open(path + "sockperf_" + str(i), "r") as f:
			lines = f.readlines()
			averagereceived = lines[0]
			averagesent = lines[1]
			averagefivenine = lines[2]
			averagefournine = lines[3]
			averagethreenine = lines[4]
			averagetwonine = lines[5]
			averageonenine = lines[6]
			averagesevenfive = lines[7]
			averagefivezero = lines[8]
			averagetwofive = lines[9]
			averageavglatency = lines[10]
			averagestddevlatency = lines[11]

			yreceived.append(float(averagereceived))
			ysent.append(float(averagesent))
			yfivenine.append(float(averagefivenine))
			yfournine.append(float(averagefournine))
			ythreenine.append(float(averagethreenine))
			ytwonine.append(float(averagetwonine))
			yonenine.append(float(averageonenine))
			ysevenfive.append(float(averagesevenfive))
			yfivezero.append(float(averagefivezero))
			ytwofive.append(float(averagetwofive))
			yavglatency.append(float(averageavglatency))
			ystddevlatency.append(float(averagestddevlatency))




	print(ysevenfive)
	print(yfivezero)
	print(ytwofive)

graphit()