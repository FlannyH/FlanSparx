INCLUDE "Code/TilemapLoaderMacros.asm"

SECTION "TilemapLoader", ROM0

;Get map width and height
GetMapMetadata:
	push bc
	push de
	push hl
	ld de, map_width
	ld a, bank(map_level_test)
	ld [set_bank], a
	ld [curr_bank], a
	ld hl, map_level_test ; load level pointer
	ld b, 2 ; We gotta read 2 bytes (b for counter)
	
	;REPEAT 2 TIMES
.mapMetadataLoop
	ld a, [hl+] ; Read one byte
	ld [de], a ; store it in de
	inc de ; move to next byte
	dec b ; decrease counter
	jr nz, .mapMetadataLoop
	pop hl
	pop de
	pop bc
	ret
	
;Loads a horizontal strip of tiles from a level into VRAM
RenderHorizontalStrip:
	push bc
	push de
	push hl
.start ; Prepare registers for the copy loop
	ld hl, map_level_test ; Locate the map data in ROM
	
	;Calculate the offset of the header + x position
	ld a, [camera_x] ; Load the player x position
	add 2 ; header is actually 3 bytes, but we start filling one byte earlier to avoid gaps when scrolling
	
	;Add the X + header offset to HL
	ld d, 0 ; Load the value of A into BC
	ld e, a
	add hl, de ; Add DE to HL
	
	;Calculate y offset
	ld a, [map_width] ; Load map width into B
	ld b, a
	ld a, [camera_y] ; Load player y coords into C
	ld c, a
	ld a, [y_offset] ; y_offset is the y offset
	rra
	add c ; add camera_y and the y offset together
	ld c, a ; store it in c
	
	;strip offset komt nog
	ld a, d ; set A to 0 (D is still 0 from the X offset calculation)
	ld e, d ; set E to 0
	yOffsetLoopRender	
.doneOffset
	ld e, a
	add hl, de
	;At this point, we have the offset in the tilemap, but not in VRAM
	;The address in VRAM is pretty simple to calculate though, as
	;the coordinates go from $00 to $1F
	;It would simply mean taking the Y coordinate, mask it with %0001 1111,
	;then bit shift it 5 times to the left.
	;Then mask the X coordinate with %0001 1111, and just sum them together
	;After that, just add the address for the tilemap
	
	;Y-coordinate
	ld a, [camera_y] ;Load camera_y into C
	rla
	ld c, a
	ld a, [y_offset] ; add the y offset to A
	add c
	and %00011111 ; mask it to fit inside 0x00 - 0x0F
	ld d, $00 ; Reset D
	;A - low, D - high
	;I'm using A instead of E, as RLA is 1 cycle and RL E is 2 cycles. In total this saves 4 cycles
	
.GetVRAMaddress 
	;Multiply by 16
	swap a
	ld b, a

	and $0F
	ld d, a

	ld a, b
	and $F0

	rla
	rl d
	
	ld e, a
	
.FinishVRAMaddress
	;Current state: DE contains VRAM Y offset, add X now
	ld a, [camera_x] ; Load camera_x into B, and mask it
	rla
	and %00011111
	ld b, a
	ld a, e ; Load E into A
	add b ; E += camera_x
	jr nc, .noCarry ; If E overflows, increase D
	inc d
.noCarry
	ld e, a
	ld a, d ; Add $98 to register D, giving us the actual destination of the tile data
	add $98
	ld d, a
	;Current situation: We have the data offset in HL, we have the VRAM offset in DE
	
	;Swap DE and HL
	push de
	push hl
	pop de
	pop hl
	
	ld c, 13 ; Let's set up the counter to copy 13 bytes of data to VRAM
	ld b, $0
	
	;call Memcpy_gpu ; Copy the data
    ld a, bank(map_level_test)
    ld [set_bank], a
    ld [curr_bank], a

.copyLoop
	;COPY BYTES
;tiles
	push bc

;Get X offset and write it to RAM (for object spawning)
	ld a, $1A ;x_offset = 0x0D - counter
	sub c
	sub c
	ld [x_offset], a

	write16x16tileToVRAM
;return to position
	ld bc, -32 ; -32
	add hl, bc

;palettes (if colour mode)
	ld a, [gameboy_type]
	cp GAMEBOY_COLOR
	jr nz, .afterPalettes

	ApplyPalette

;return to position
	ld bc, -32 ; -32
	add hl, bc


	xor a ; ld a, 0
	ld [rVBK], a ; switch back to bank 0


.afterPalettes
	pop bc
	inc de
	;INCREASE HL AND DETECT TILEMAP WRAPPING
	ld a, l ; if (l % 0x20 == 31)
	and $1f
	cp 31
	jr nz, .increaseHL

	;WRAP
	ld a, l ; l -= 0x20
	sub $20
	ld l, a
	jr nc, .increaseHL ; if l is now under 0, decrease h, otherwise, skip (this means that we basically remove 0x20 from HL)
	dec h

.increaseHL
	inc hl

	dec c
	jp nz, .copyLoop
	ei
.end
	pop hl
	pop de
	pop bc
	ret	

;Loads a vertical strip of tiles from a level in to VRAM
RenderVerticalStrip:
	push bc
	push de
	push hl
.start ; Prepare registers for the copy loop
	ld hl, map_level_test ; Locate the map data in ROM
	
	;Calculate the offset of the header + x position
	ld a, [camera_x] ; Load the player x position
	add 2 ; header is actually 3 bytes, but we start filling one byte earlier to avoid gaps when scrolling
	ld c, a
	ld a, [x_offset] ; x_offset is the x offset
	rra
	add c ; add camera_x and the x offset together
	ld c, a ; store it in c
	
	;Add the X + header offset to HL
	ld b, 0 ; Load the value of A into BC
	ld c, a
	add hl, bc ; Add BC to HL
	
	;Calculate y offset
	ld a, [map_width] ; Load map width into B
	ld b, a
	ld a, [camera_y] ; Load player y coords into C
	ld c, a
	
	;strip offset komt nog
	ld a, $00 ; prepare A
	ld d, a ; stores low byte
	ld e, a ; stores high byte
	yOffsetLoopRender
.doneOffset
	ld e, a
	add hl, de
	;At this point, we have the offset in the tilemap, but not in VRAM
	;The address in VRAM is pretty simple to calculate though, as
	;the coordinates go from $00 to $1F
	;It would simply mean taking the Y coordinate, mask it with %0001 1111,
	;then bit shift it 5 times to the left.
	;Then mask the X coordinate with %0001 1111, and just sum them together
	;After that, just add the address for the tilemap
	
	;Y-coordinate
	ld a, [camera_y] ;Load camera_y into C
	rla
	ld c, a
	and %00011111 ; mask it to fit inside 0x00 - 0x0F
	ld d, $00 ; then put it in a 16 bit register
	ld e, a
	ld b, 5 ; set the counter to 5
	
.GetVRAMaddress
	or a ; Set carry flag to 0
	rl e ; Shift E to the left once
	rl d ; Shift D to the left once, using E's carry bit
	dec b ; counter--;
	jr nz, .GetVRAMaddress
	
.FinishVRAMaddress
	;Current state: DE contains VRAM Y offset, add X now
	ld a, [camera_x] ; Load camera_x into B, add the x offset and mask it
	rla
	ld b, a
	ld a, [x_offset]
	add b
	and %00011111
	ld b, a
	ld a, e ; Load E into A
	add b ; E += camera_x
	jr nc, .noCarry ; If E overflows, increase D
	inc d
.noCarry
	ld e, a
	ld a, d ; Add $98 to register D, giving us the actual destination of the tile data
	add $98
	ld d, a
	;Current situation: We have the data offset in HL, we have the VRAM offset in DE
	
	;Swap DE and HL
	ld b, d
	ld c, e
	
	ld d, h
	ld e, l
	
	ld h, b
	ld l, c
	
	ld c, 11 ; Let's set up the counter to copy 11 bytes of data to VRAM
	ld a, [map_width] ; load map_width into B
	ld b, a

	;call Memcpy_gpu ; Copy the data
    ld a, bank(map_level_test)
    ld [set_bank], a
    ld [curr_bank], a

.copyLoop
	;COPY BYTES
;tiles
	push bc
;Get Y offset and write it to RAM (for object spawning)
	ld a, $16 ;Y_offset = 0x0D - counter
	sub c
	sub c
	ld [y_offset], a

	write16x16tileToVRAM
;return to position
	ld bc, -32 ; -32
	add hl, bc
	
;palettes (if colour mode)
	ld a, [gameboy_type]
	cp GAMEBOY_COLOR
	jr nz, .noPalettes ; if not gameboy color, skip palettes

	ApplyPalette

	xor a ; ld a, 0
	ld [rVBK], a ; switch back to bank 0
	jr .afterPalettes

.noPalettes
	ld bc, $20
	add hl, bc

.afterPalettes
;return to position
	ld bc, $FFDF ; -21 ; back to top left
	add hl, bc
	pop bc
	;MOVE VRAM POINTER
	ld a, l ; go down 2 tiles (move right by two screen width (being 0x20))
	add $40 
	ld l, a
	jr nc, .noCarryVRAMCopyLoop ; if overflow, increase h, otherwise, skip
	inc h
.noCarryVRAMCopyLoop
	; if past tile memory, wrap around
	ld a, h
	cp $9C ; $9C00 is past the background tile map, wrap around if this would have been the target VRAM address
	jr nz, .noWrap
	sub 4
	ld h, a
.noWrap
	; MOVE TILEMAP POINTER
	; DE += map_width
	ld a, e ; go down 1 y coordinate (move right by one map width)
	add b
	ld e, a
	jr nc, .noCarryTilemapCopyLoop ; if overflow, increase h, otherwise, skip
	inc d
.noCarryTilemapCopyLoop
	ld a, e
	add b
	;COUNTER
	dec c
	jp nz, .copyLoop
	
.end
	ei;
	pop hl
	pop de
	pop bc
	ret	

;Copy a whole screen worth of tiles to VRAM	
RenderScreen:
	push bc
	push hl
	ld b, 11 ; counter = 11
	ld c, $01 ; y offset
	ld hl, camera_y
.renderScreenLoop
	;Pass the y offset as argument 1
	call RenderHorizontalStrip
	inc [hl]
	dec b
	jr nz, .renderScreenLoop

	ld a, [camera_y]
	sub 11
	ld [camera_y], a

	pop hl
	pop bc
	
	ret

;Copy a whole screen worth of tiles to VRAM, but in vertical strips, for debugging reasons	
RenderScreenVertical:
	push bc
	push hl
	ld b, 13 ; counter = 11
	ld c, $01 ; x offset
	ld hl, camera_x
.renderScreenLoop
	;Pass the y offset as argument 1
	call RenderVerticalStrip
	inc [hl]
	dec b
	jr nz, .renderScreenLoop

	ld a, [camera_x]
	sub 13
	ld [camera_x], a

	pop hl
	pop bc
	
	ret
	
;Scroll the tile viewport based on camera_x, camera_y, scroll_x and scroll_y
ScrollScreen:
	push bc
	push hl
	;----X scroll----
	ld a, [scroll_x] ; Load scroll_x into B
	ld b, a
	
	ld a, [camera_x] ; Load camera_x into A
	
	;Multiply camera_x by 16 to get pixel position instead of tile position
	
	;a = a << 4;
	;a = a % 0b11111000
	;The mask is for any carry bits that ended up in the rightmost 3 bits
	swap a
	and %11110000
	
	;Then add scroll_x to all of this
	add b
	
	;Finally add 8 so the map is scrolled past the loading seam
	ld [abs_scroll_x], a
	add 16
	ld d,d
	ld [rSCX], a
	
	;----Y scroll----
	ld a, [scroll_y] ; Load scroll_y into B
	ld b, a
	
	ld a, [camera_y] ; Load camera_y into A
	
	;Multiply camera_y by 16 to get pixel position instead of tile position
	
	;a = a << 4;
	;a = a % 0b11111000
	;The mask is for any carry bits that ended up in the rightmost 3 bits
	swap a
	and %11110000
	
	;Then add scroll_y to all of this
	add b
	
	;Finally add 16 so the map is scrolled past the loading seam
	ld [abs_scroll_y], a
	add 16
	
	ld [rSCY], a
	
	pop hl
	pop bc
	ret
	
;Scroll the screen 1 pixel to the right
ScrollRight:
	;Load scroll_x into A, increase it, check if it's 8,
	push hl
	ld a, [scroll_x]
	inc a
	ld [scroll_x], a
	cp 16
	jr nz, .end
	;If it's 8, do not return yet, update camera_x, load a row of tiles and then return
	xor a ; ld a, 0
	ld [scroll_x], a
	ld hl, camera_x
	inc [hl]
	ld a, $16
	ld [x_offset], a
	call ScrollScreen
	call RenderVerticalStrip
	pop hl
	ret
.end
	call ScrollScreen
	pop hl
	ret
	
;Scroll the screen 1 pixel to the left, and load a new row of tiles if necessary
ScrollLeft:
	;Load scroll_x into A, decrease it, check if it's -8,
	push hl
	ld a, [scroll_x]
	dec a
	ld [scroll_x], a
	cp -16;$F0
	jr nz, .end
	;If it's -8, do not return yet, update camera_x, and then return
	xor a ; ld a, 0
	ld [scroll_x], a
	ld hl, camera_x
	dec [hl]
	xor a ; a = 0
	ld [x_offset], a
	call ScrollScreen
	call RenderVerticalStrip
	pop hl
	ret
.end
	call ScrollScreen
	pop hl
	ret

;Scroll the screen 1 pixel down
ScrollDown:
	;Load scroll_y into A, increase it, check if it's 16,
	push hl
	ld a, [scroll_y]
	inc a
	ld [scroll_y], a
	cp 16
	jr nz, .end
	;If it's 8, do not return yet, update camera_y, load a row of tiles and then return
	xor a ; ld a, 0
	ld [scroll_y], a
	ld hl, camera_y
	inc [hl]
	ld a, $14
	ld [y_offset], a
	call ScrollScreen
	call RenderHorizontalStrip
	pop hl
	ret
.end
	call ScrollScreen
	pop hl
	ret
	
;Scroll the screen 1 pixel up
ScrollUp:
	;Load scroll_y into A, decrease it, check if it's -16,
	push hl
	ld a, [scroll_y]
	dec a
	ld [scroll_y], a
	cp -16
	jr nz, .end
	;If it's -8, do not return yet, update camera_y, load a row of tiles and then return
	xor a ; ld a, 0
	ld [scroll_y], a
	ld hl, camera_y
	dec [hl]
	xor a ; a = 0
	ld [y_offset], a
	call ScrollScreen
	call RenderHorizontalStrip
	pop hl
	ret
.end
	call ScrollScreen
	pop hl
	ret

