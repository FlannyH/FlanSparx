import sys
import os

#Usage: data_inserter.py <rom> <file to insert> <rom offset>

print (sys.argv)

rom_path = sys.argv[1]
to_insert_path = sys.argv[2]
rom_offset = int(sys.argv[3], 16)

try:
	os.remove("tmp.gb")
except FileNotFoundError:
	pass
os.rename(rom_path, "tmp.gb")

rom = open("tmp.gb", "rb")
data_to_insert = open(to_insert_path, "rb").read()
output = open(rom_path, "wb")

#Insert data

output.write(rom.read(rom_offset))
output.write(data_to_insert)
rom.seek(len(data_to_insert)+rom_offset)
output.write(rom.read())
output.close()

#Calculate checksum

output = open(rom_path, "rb+")
output.seek(0x014E)
print(int.from_bytes(output.read(2), 'big'))
output.seek(0x0000)
checksum = 0
for x in range(0x14E):
	try:
		checksum += output.read(1)[0]
	except IndexError:
		#No more data, move on
		break
output.seek(0x0150)
while True:
	try:
		checksum += output.read(1)[0]
	except IndexError:
		#No more data, move on
		break
checksum = checksum & 0xFFFF
print (checksum)
output.seek(0x14E)
output.write(bytes([(checksum >> 8), (checksum & 0xFF)]))
output.close()