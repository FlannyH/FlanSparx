import pygame
infile = pygame.image.load("chr000_bw.bmp")
outfile = open("chr000_bw.bin", "wb")

tile_x = 0
tile_y = 0
sub_x = 0
sub_y = 0

gameboy_grey_list = [
[0, 0, 0, 255], 
[64, 64, 64, 255],
[128, 128, 128, 255],
[255, 255, 255, 255]
]

def GetDistance(a, b):
	result = 0
	result += (a[0] - b[0]) ** 2
	result += (a[1] - b[1]) ** 2
	result += (a[2] - b[2]) ** 2
	result = result ** 0.5
	return result

def ProcessTile():
	for sub_y in range(8):
		#Get row of 8 pixels
		current_pixels = list()
		for sub_x in range(8):
			color = infile.get_at(((tile_x*8)+sub_x, (tile_y*8)+sub_y))
			current_pixels.append (bin(gameboy_grey_list.index(list(color)))[2:].zfill(2))
		#print (current_pixels)
		#First bit
		first_bit = ""
		for x in current_pixels:
			first_bit += x[1]
		#Second bit
		second_bit = ""
		for x in current_pixels:
			second_bit += x[0]
		outfile.write(bytes([int(first_bit, 2)]))
		outfile.write(bytes([int(second_bit, 2)]))

unique_colors = list()
while True:
	try:
		for x in range(8):
			tile_x = 2*x
			ProcessTile()
			tile_x += 1
			ProcessTile()
			tile_x = 2*x
			tile_y += 1
			ProcessTile()
			tile_x += 1
			ProcessTile()
			tile_y -= 1
		tile_y += 2
	except IndexError: #End of file
		break