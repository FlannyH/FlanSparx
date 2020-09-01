#generate color palettes for gameboy color
colors = [
[0, 0, 0],
[0, 0, 0],
[163, 0, 0],
[255, 72, 72]
]
binstr = "dw "
for color in colors:
	binstr += "%"
	#blue
	x = color[2]
	x = x/255
	x *= 31
	x = int(round(x))
	x = bin(x)[2:].zfill(5)
	binstr += x
	#green
	x = color[1]
	x = x/255
	x *= 31
	x = int(round(x))
	x = bin(x)[2:].zfill(5)
	binstr += x
	#red
	x = color[0]
	x = x/255
	x *= 31
	x = int(round(x))
	x = bin(x)[2:].zfill(5)
	binstr += x
	binstr += ", "
	
print (binstr[:-2])