SECTION "Timer", ROM0[$50]
	jp ReadNextPartWave

SECTION "WaveUpdate", ROM0
WaveStart:
;Start counter
ld a, TACF_START | TACF_4KHZ
ld [rTAC], a


;Enable sound
ld a, $80
ld [rNR52], a
ld a, $FF
ld [rNR51], a
ld a, $77
ld [rNR50], a

;DE: wave pointer
ld a, $40
ld [music_registers+2], a

;C: bank counter
ld a, 3
ld [music_registers+1], a
ld a, [gameboy_type]
cp GAMEBOY_COLOR
ld a, -8
jr nz, .GameboyColorTimingSoSkipTheOtherOne
sub 8 ; ld a, -16

.GameboyColorTimingSoSkipTheOtherOne
	LD [rTMA], a

ret

ReadNextPartWave:
    di
    push af
    push bc
    push de
    push hl
;Read music state from ram
    ;ld a, [music_registers]
    ;ld b, a
	ld hl, music_registers+1
	ld c, [hl]
	inc l
	ld d, [hl]
	inc l
	ld e, [hl]

;Make sure we're in the right ROM bank
	ld a, c
	ld [$2000], a
;Disable wave
	xor a ; ld a, %00000000
	ld [rNR30], a

	ld hl, _AUD3WAVERAM
	
	;Unrolled loop, save cpu
	rept 15
	ld a, [de]
	ld [hl+], a
	inc e
	endr

	ld a, [de]
	ld [hl+], a

;Enable wave
	ld a, %10000000
	ld [rNR30], a
	ld [rNR33], a
	ld a, %00100000
	ld [rNR32], a
	ld a, %10000111
	ld [rNR34], a
	inc de

;Check if bank counter needs to be incremented
	bit 7, d ; if d >= 0x80
	jr z, .noReset
	inc c
;Switch to start of new bank
	ld d, $40 ; ld de, $4000    
.noReset


;Store variables in RAM
    ;ld a, b
    ;ld [music_registers], a
	ld hl, music_registers+1
	ld [hl], c
	inc l
	ld [hl], d
	inc l
	ld [hl], e

	ld a, [curr_bank]
	ld [set_bank], a

    pop hl
    pop de
    pop bc
    pop af

	reti