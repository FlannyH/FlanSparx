SECTION "ObjGemBlue", ROM0
;Input: DE - pointer to the 2nd byte of object table entry ([DE] points to the type)
DrawSprite_GemBlue:
;- Update Sprite
    ld l, e
    ld h, d

    ;Get gem sprite order + palette
    ld de, GemBlue
    
    ;OAM pointer
    ld bc, -4
    add hl, bc

    ;left
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl+], a
    inc de
    inc l
    inc l
    ;right
    ld a, [de]
    ld [hl+], a
    inc de
    ld a, [de]
    ld [hl], a
    dec l
    ret

;Input: DE - pointer to the 2nd byte of object table entry ([DE] points to the type)
PlayerCollision_GemBlue:
    ;Add 5 gems to total gem count
    ld a, [current_gem_count]
    add 5
    ld [current_gem_count], a

    ;Update decimal values
    ld a, [current_gem_dec2]
    add 5
    daa
    ld [current_gem_dec2], a
    jr nc, .noCarry
    
    ;If the DAA decimal value overflows, increment the high byte
    ld a, [current_gem_dec1]
    inc a
    ld [current_gem_dec1], a


    .noCarry
    ;Then get the object ID and delete that object
    ld a, [de]
    call DeleteObject
    ret