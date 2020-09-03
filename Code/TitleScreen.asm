SECTION "Title Screen", ROM0
PrepareTitleScreenData:
    di
;PALETTES
	ld a, [gameboy_type]
	cp GAMEBOY_COLOR
	jr nz, .GameboyRegularPalettes
    .GameboyColorPalette
    ;BG PALETTES
    	ld hl, $FF68 ; Palette select register
    	xor a ; ld a, 0
    	or %10000000
    	ld [hl+], a

    	ld b, 16 ; 16 bytes for 2 palettes
    	ld de, PalettesTitleScreenBG
    .paletteLoopBG
    	ld a, [de]
    	ld [hl], a
    	inc e
    	dec b
    	jr nz, .paletteLoopBG

    .GameboyRegularPalettes
    	; Init display registers
    	ld a, %00011011 ; palette, just default black to white
    	ld [rBGP], a
    	ld [rOBP0], a
    
    .endPalettes
;TILESET
    ;Map tiles part 1
	ld hl, $9000
	ld de, TitleScreenTileset
	ld bc, $800
	ld a, bank(TitleScreenTileset)
	ld [set_bank], a
	call Memcpy

	;Map tiles part 2
	ld hl, $8800
	ld de, TitleScreenTileset+$800
	ld bc, $800
	call Memcpy
;BUILD MAIN MENU SCREEN
    ld de, TitleScreenMap ; source
    ld hl, _SCRN0 ; destination
    ld b, 18 ; height
    .yLoop
        ld c, 20 ; width
        .xLoop
            ;copy a byte from DE to HL, then increase both
            ld a, [de]
            inc de
            ld [hl+], a
            dec c
            jr nz, .xLoop
        ld a, l
        and %11100000 ; x = 0 (makes L a multiple of 0x20, effectively resetting x to 0)
        add $20 ; then add $20 to move it down 1 tile
        ld l, a
        ;and make sure H gets updated as well when necessary (which is when L overflows)
        ld a, h
        adc $00
        ld h, a
        ;count down y loop counter
        dec b
        jr nz, .yLoop

;END
    ;Clean OAM - on the regular gameboy, OAM starts with garbage data. On the gameboy color it's not really an issue, but clean it anyway
	call PrepareSpriteData
    ld  a, HIGH(wShadowOAM)
    call hOAMDMA
	;Turn on screen and enable background layer
	ld a, (LCDCF_ON + LCDCF_OBJON + LCDCF_BGON)
	ld [rLCDC], a
    ret


Scene_TitleScreen:
    call PrepareTitleScreenData
    call waitForPlayerToPressStart
    ret

SECTION "Title Screen Palettes", ROM0
PalettesTitleScreenBG:
    dw %0000000000000110, %0100110101101111, %0000101000011100,  %0111111111111111

SECTION "Title Screen Graphics", ROMX
TitleScreenTileset:
    INCBIN "Resources/tileset_title_screen.bin"
TitleScreenTilesetEnd:

SECTION "Title Screen Map", ROMX
TitleScreenMap:
    INCBIN "Maps/title_screen.bin"
TitleScreenMapEnd: