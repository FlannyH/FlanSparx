import wave
import sys

name = sys.argv[1].replace(".wav","")

infile = wave.open(f"{name}.wav", 'rb')
outfile = open(f"{name}.bin", "wb")
frame = 0

current_byte = 0

while frame != None:
	curr_byte = 0
	frame = infile.readframes(1)[0]
	frame = int(round(frame/255*15))
	curr_byte |= frame
	curr_byte = curr_byte << 4
	frame = infile.readframes(1)[0]
	frame = int(round(frame/255*15))
	curr_byte |= frame
	outfile.write(bytes([curr_byte]))
	current_byte += 1
	if current_byte > 7*1024*1024:
		exit()