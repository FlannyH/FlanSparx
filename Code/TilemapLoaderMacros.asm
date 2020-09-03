SECTION "Tilemap Loader Macros", ROM0
write16x16tileToVRAM: MACRO
	di;
    ;Load tile bank
    ld a, bank(map_level_test)
    ld [set_bank], a
    ld [curr_bank], a
	ld a, [de] ; read byte from tilemap
	ei;
	cp $40 ; if < 40
	jr c, .RegularTile\@ ; continue
	;otherwise make it a ground tile, we'll program objects in some other time

	call SpawnObject
	

	ld a, 1 ; ground tile

    .RegularTile\@
	or a
	rla ; a *= 4
	rla
	;top
		;WAIT FOR VRAM ACCESS
		di
		waitForRightVRAMmode
		ld [hl+], a ; write byte to vram
		inc a
		ld [hl], a ; write byte to vram
		inc a
	;bottom
		;move from top right to bottom left (-1 and then +32)
		waitForRightVRAMmode
		ld bc, $1F
		add hl, bc
		ld [hl+], a ; write byte to vram
		inc a
		ld [hl], a ; write byte to vram
		ei
ENDM
ApplyPalette: MACRO
;get into position
	dec hl
	;ld bc, -2 ; go back to the tile you just wrote, but this time in vram bank 1
	ld a, 1
;switch to bank 1
	ld [rVBK], a 
;get palette
    ld a, bank(map_level_test)
    ld [curr_bank], a
    ld [set_bank], a
	ld a, [de] ; read byte from tilemap -> A,
	cp $40 ; if < 40
	jr c, .RegularTile\@ ; continue
	;otherwise make it a ground tile, we'll program objects in some other time
	ld a, 1 ; ground tile
	.RegularTile\@
	ld b, a

	push de

	ld de, TilePaletteMapping
	ld a, e
	add b
	ld e, a
	ld a, [de]

	;WAIT FOR VRAM ACCESS
	di
	waitForRightVRAMmode
;write palette data
	ld [hl+], a
	ld [hl], a
	ld bc, $1F
	add hl, bc
	ld [hl+], a
	ld [hl], a
	ei
	pop de
ENDM
;Function used in both horizontal and vertical strip functions; make it a global function to save rom space
yOffsetLoopRender: MACRO
	inc c

.loop\@
	dec c
	jr z, .afterLoop\@
	
	add a, b ; a += map_width
	jr nc, .loop\@ ; If no overflow, jump to checkIfDone
	inc d ; if A overflows, increment d
	jr .loop\@
	
.afterLoop\@
ENDM