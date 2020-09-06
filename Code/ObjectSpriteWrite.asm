SECTION "Write Sprite to OAM", ROM0
;Writes an object into OAM, getting the position and direction from RAM
;Input:
; - DE: 
WriteSprite:
.leftSprite
    ;LEFT SPRITE
    ; Y position
    ;load coordinates - abs_scroll_y
    ld a, [abs_scroll_y]

    ld b, a
    ;get fine offset y -> C
    inc e
    inc e
    inc e
    inc e
    ld a, [de]
    ld c, a
    dec e
    dec e
    dec e
    dec e
    ld a, [de]
    
    ;position from 16x16 tile -> pixel
    or a
    rla
    rla
    rla
    sub b
    add c ; fine position offset

    ld [hl+], a ; write to shadow oam

    ; X position
    ;load coordinates - abs_scroll_x, and check if not too far off screen
    inc e

    inc e
    inc e
    inc e
    inc e
    ld a, [de]
    ld c, a
    dec e
    dec e
    dec e
    dec e
    ld a, [abs_scroll_x]
    ld b, a
    ld a, [de]
    
    ;position from 16x16 tile -> pixel
    or a
    rla
    rla
    rla
    sub 12 ; sprite offset
    sub b
    add c ; fine position x

    ld [hl+], a ; write to shadow oam

    inc l
    inc l
    dec e
.rightSprite
    ;RIGHT SPRITE
    ; Y position
    ;load coordinates - abs_scroll_y
    ld a, [abs_scroll_y]

    ld b, a
    ;get fine offset y -> C
    inc e
    inc e
    inc e
    inc e
    ld a, [de]
    ld c, a
    dec e
    dec e
    dec e
    dec e
    ld a, [de]
    
    ;position from 16x16 tile -> pixel
    or a
    rla
    rla
    rla

    sub b
    add c
    ld [hl+], a

    ; X position
    ;load coordinates - abs_scroll_x
    inc e
    ;get fine offset x -> C
    inc e
    inc e
    inc e
    inc e
    ld a, [de]
    ld c, a
    dec e
    dec e
    dec e
    dec e
    ld a, [abs_scroll_x]
    ld b, a
    ld a, [de]
    
    ;position from 16x16 tile -> pixel
    or a
    rla
    rla
    rla
    sub 4

    sub b
    add c
    ld [hl+], a
    ret