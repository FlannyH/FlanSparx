SECTION "MiscFunctions", ROM0


;ClearRAM is a function to reset all the WRAM on the Game Boy.
;This is necessary because the Game Boy will probably have garbage
;data in WRAM on startup. This will make debugging more difficult,
;and could cause issues if not careful.
;This function writes $00 to every WRAM address
ClearRAM:
	ld hl, $DFFF ; set pointer to the end of RAM
	xor a ; ld a, 0 ; the value we're gonna fill the ram with
.fillRAMwithZeros
	ld [hl-], a ; write a zero
	bit 6, h
	jr nz, .fillRAMwithZeros
	ret
	
ClearHRAM:
	ld hl, $FFFE ; set pointer to HRAM
	xor a ; ld a, $00 ; the value we're gonna fill the ram with
.fillHRAMwithZeros
	ld [hl-], a ; write a zero
	bit 7, l
	jr nz, .fillHRAMwithZeros ; keep going until we reach $FF80
	ret	

SetupInterrupts:
	;Enable VBLANK interrupt
	ld a, [rIE]
	or IEF_VBLANK + IEF_TIMER + IEF_LCDC
	ld [rIE], a
	ei
	ret

waitVBlank:
	ei
.wait
	halt
	ld a, [rLY]
	cp 144 ; Check if past VBlank
	jr c, .wait ; Keep waiting until VBlank is done
	ret
	
turnOffLCD:
	ld a, [rLCDC]
	res 7, a
	ld [rLCDC], a
	ret
	
turnOnLCD: MACRO
	ld a, [rLCDC]
	set 7, a
	ld [rLCDC], a
ENDM
	
debugHalt:
	jr debugHalt

CalculateAbsoluteScroll: MACRO
	push bc
	;X
	ld a, [scroll_x] ;scroll_x -> b
	ld b, a
	ld a, [camera_x] ; camera_x -> a
	and %00001111 ; does the same as
	swap a	      ; bitshifting to the left 4x
	add b ; add them together
	ld [abs_scroll_x], a  ; poof absolute scroll
	
	;Y
	ld a, [scroll_y] ;scroll_y -> b
	ld b, a
	ld a, [camera_y] ; camera_y -> a
	and %00001111 ; does the same as
	swap a	      ; bitshifting to the left 4x
	add b ; add them together
	ld [abs_scroll_y], a  ; poof absolute scroll

	pop bc
ENDM
	
waitForRightVRAMmode: MACRO
	push hl
	ld hl, rSTAT
.waitForMode\@
	bit 1, [hl]
	jr nz, .waitForMode\@
	pop hl
ENDM

Memcpy:
	ld a, [de] ; Read one byte
	ld [hl+], a ; Write it to the destination
	inc de ; Go to next byte
	dec bc ; Decrement counter
	ld a, b ; or B and C together and check if it's zero
	or c
	jr nz, Memcpy ; if it's not zero, keep going
	ret

Memcpy8:
	ld a, [de] ; Read one byte
	ld [hl+], a ; Write it to the destination
	inc de ; Go to next byte
	dec b ; Decrement counter
	jr nz, Memcpy8 ; if it's not zero, keep going
	ret
	
Memcpy_gpu:
	waitForRightVRAMmode
	ld a, [de] ; Read one byte
	ld [hl+], a ; Write it to the destination
	inc de ; Go to next byte
	dec bc ; Decrement counter
	ld a, b ; or B and C together and check if it's zero
	or c
	jr nz, Memcpy_gpu ; if it's not zero, keep going
	ret

waitForPlayerToPressStart:
	push af
	.keepWaiting
	;Wait a frame
	call waitVBlank

	;Check buttons
	call GetJoypadStatus

	;Did the player press start yet?
	ld a, [joypad_pressed]
	bit J_START, a

	;If not, check again
	jr z, .keepWaiting

	;Otherwise, return
	pop af
	ret

MoveStack:
	;We're going to work our way up the stack
	;Load SP into HL and DE
	ld hl, sp+0
	ld d, h
	ld e, l

	;Then make both HL and SP point to the destination in WRAM
	ld h, $CE
	ld sp, hl

	.loop
		ld a, [de]
		ld [hl+], a
		inc e
		jr nz, .loop
	
	ret

DisableWindow:
    waitForRightVRAMmode

	;Disable window
	ld a, [rLCDC]
	and ~LCDCF_WINON

	;Enable sprites
	or LCDCF_OBJON

    ;Switch back to map tileset
    and ~LCDCF_BG8000
    ld [rLCDC], a

	;Trigger an interrupt when it enters Vblank, so it can enable the window again for the next frame
	ld a, 144
	ld [rLYC], a

	pop af
	reti

EnableWindow:
	;After VBLANK, enable the window layer for the GUI	
	ld a, [rLCDC]
	or LCDCF_WINON
	
	;Disable sprites
	and ~LCDCF_OBJON

    ;Switch to sprite/ui tileset
    or LCDCF_BG8000
    ld [rLCDC], a

	;Trigger an interrupt so it stops displaying the window after 16 scanlines
	ld a, 8
	ld [rLYC], a

	pop af
	reti

LYinterrupt:
	push af
	ld a, [rLY]
	cp 144
	jp nc, EnableWindow ;Enable window if in VBLANK
	jp DisableWindow

	;just in case something weird happens, trust me, a lot of weird shit has happened with this stupid interrupt
	pop af
	reti


SECTION "VBlank", ROM0[$40]
VBlankInterrupt:
	di
	push hl
	ld hl, frame_counter
	inc [hl]
	pop hl
	reti

SECTION "LCDC", ROM0[$48]
STATinterrupt:
	di
	jp LYinterrupt