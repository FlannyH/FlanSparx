"../COMPILER/rgbasm" -o FlanSparx.o FlanSparx.asm
"../COMPILER/rgblink" -n FlanSparx.sym -o FlanSparx.gbc FlanSparx.o
"./Dev Tools/data_inserter.py" ./Resources/spyro3_title_screen.bin 0x16000
"../COMPILER/rgbfix" -j -t FlanTest -v -c -m 25 -p 0 FlanSparx.gbc
start FlanSparx.gbc