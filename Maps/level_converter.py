import sys
level = open(sys.argv[1])
binary = open(sys.argv[1].replace("..", ".").replace(".csv", ".bin"), "wb")

#Get size
data = level.readlines()
height = (len(data))
width = (len(data[0].split(",")))
binary.write(bytes([width, height, 0]))

level.seek(0)

#Get data
data = level.read().replace("\n",",").split(",")
data = bytes([int(x) for x in data[:-1]])
binary.write(data)