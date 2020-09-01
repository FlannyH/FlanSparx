infile = open("Variables.asm", "r")
outfile = open("Variables.sym", "w")

outarray = list()

for line in infile.readlines():
	if "EQU" in line:
		line = line.replace("\n","") #Remove newline
		line = line.replace("\t","") #Remove spacing 1
		line = line.replace(" ","")  #Remove spacing 2
		line = line.split(";")[0]	 #Remove comments
		line = line.split("EQU")	 #Split
		if len(line) > 1:
			if "$" in line[1] and len(line[1]) == 5:
				line[1] = line[1][1:]
				
				outarray.append (f"00:{line[1]} {line[0]}")
			
outarray.sort()
for line in outarray:
	outfile.write(line + "\n")