import sys
filename = sys.argv[1]
IF = open(sys.argv[1], "rb")
OF = open("converted_" + sys.argv[1], "wb")

while (data := IF.read(2)):
	binary = bin(int.from_bytes(data, byteorder='big'))[2:].zfill(15)
	print ("b:", binary[0:5]  )
	print ("g:", binary[5:10] )
	print ("r:", binary[10:15])
	print ()
	b = round(int(binary[0:5]  ,2) / 31 * 255)
	g = round(int(binary[5:10] ,2) / 31 * 255)
	r = round(int(binary[10:15],2) / 31 * 255)
	OF.write(bytes([r,g,b]))