infile = open("spyro_logo_to_be_compressed", "rb")
outfile = open("compressedfile.bin", "wb")
while True:
	#read 8 bytes
	data = infile.read(8)
	
	if (len(data) == 0):
		break
	
	#if they're not all 0, write the 8 bytes
	sum = 0
	for b in data:
		sum += b
	if sum != 0:
		outfile.write(data)
print ("done")