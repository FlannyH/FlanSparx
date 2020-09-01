SECTION "Init", ROM0

Init:
	push af ; A contains game system flag, store it for now while we clear ram

	; Turn off the LCD
	call SetupInterrupts
	call waitVBlank
	call turnOffLCD
	call ClearRAM
	call MoveStack
	call ClearHRAM
	pop af
	
	; Get game system flag and store it in RAM (A is initialized with a different byte depending on which system you're using)
	ld [gameboy_type], a

	; No sound
	ld [rNR52], a
	
	;Show title screen
	call Scene_TitleScreen

	;Wait for frame to finish, then turn off the screen so we can write to VRAM more quickly
	call SetupInterrupts
	call waitVBlank
	call turnOffLCD

	ld a, [gameboy_type]
	cp GAMEBOY_COLOR
	jr nz, .GameboyRegularPalettes

	;CPU 2x
	ld a, 1
	ld [rKEY1], a
	stop

.GameboyColorPalettes
;BG PALETTES
	ld hl, rBCPS ; Palette select register
	xor a ; ld a, 0
	or %10000000
	ld [hli], a

	ld b, 8*8 ; 8 bytes for 1 palettes
	ld de, PalettesBG
.paletteLoopBG
	ld a, [de]
	ld [hl], a
	inc de
	dec b
	jr nz, .paletteLoopBG

;OBJ PALETTES
	ld hl, rOCPS ; Palette select register
	xor a ; ld a, 0
	or %10000000
	ld [hli], a

	ld b, 8*8 ; 8 bytes for 1 palette
	ld de, PalettesOBJ
.paletteLoopOBJ
	ld a, [de]
	ld [hl], a
	inc de
	dec b
	jr nz, .paletteLoopOBJ

	jr .endPalettes

.GameboyRegularPalettes
	; Init display registers
	ld a, %00011011 ; palette, just default black to white
	ld [rBGP], a
	ld [rOBP0], a
	
.endPalettes

	;Map tiles part 1
	ld hl, $9000
	ld de, MapTiles
	ld bc, $800
	ld a, bank(MapTiles)
	ld [set_bank], a
	ld [curr_bank], a
	call Memcpy

	;Map tiles part 2
	ld hl, $8800
	ld de, MapTiles+$800
	ld bc, $800
	call Memcpy

	;Set player position
	ld a, $2f
	ld [camera_x], a
	ld a, $22
	ld [camera_y], a

	;Set player fine position
	ld a, -8
	ld [scroll_x], a
	xor a ; ld a, 0
	ld [scroll_y], a

	;Set player rotation
	ld a, SPRITE_W
	ld [player_direction], a

	call PrepareSpriteData
	call GetMapMetadata
	call ScrollScreen
	call RenderScreen
	
	ld hl, player_x
	ld [hl], $0A*8
	ld hl, player_y
	ld [hl], $0A*8
	ld hl, player_health
	ld [hl], 6

	xor a; a = 0

	ld a, 12 ; fire rate: one bullet every 12 frames
	ld [current_fire_rate], a

	;Setup LYC interrupt to disable the window after a set amount of scanlines
	ld a, [rSTAT]
	or STATF_LYC ; Setup interrupt
	ld [rSTAT], a

	ld a, 8 ; set window to appear for only the first 8 scanlines
	ld [rLYC], a

	ld a, 7
	ld [rWX], a

	;Fill window with $7F
	ld hl, $9C3F ; end of second horizontal row of visible window
	ld a, $7F
	.emptyWindow
		ld [hl-], a
		bit 2, h
		jr nz, .emptyWindow

	;Fill window with the right color palette, if this is a gameboy color
	ld a, [gameboy_type]
	cp GAMEBOY_COLOR
	jr nz, .noWindowColor

	;Switch to VRAM bank 01 - attributes and palettes
	ld a, 1
	ld [rVBK], a

	ld hl, $9C3F ; end of second horizontal row of visible window
	ld a, $02 ; the palette we're using is background palette $02
	.emptyWindowColor
		ld [hl-], a
		bit 2, h
		jr nz, .emptyWindowColor

	;Switch back to VRAM bank 00
	ld a, 0
	ld [rVBK], a

	.noWindowColor

	;Turn on screen, enable background layer, enable sprites, set 8x16 sprite mode, and set the window tilemap to the right spot
	ld a, (LCDCF_ON + LCDCF_OBJON + LCDCF_BGON + LCDCF_OBJ16 + LCDCF_WIN9C00)
	ld [rLCDC], a
    ret