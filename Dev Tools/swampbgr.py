import sys
instr = sys.argv[1]
outstr = instr[10:15] + instr[5:10] + instr[:5]
print (outstr)