SECTION "ObjGemRed", ROM0
;Input: DE - pointer to the 2nd byte of object table entry ([DE] points to the type)
DrawSprite_GemRed:
;- Update Sprite
    ld l, e
    ld h, d

    ;Get gem sprite order + palette
    ld de, GemRed
    
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
PlayerCollision_GemRed:
    ;Add 1 gem to total gem count
    ld a, [current_gem_count]
    inc a
    ld [current_gem_count], a

    ;Update decimal values
    ld a, [current_gem_dec2]
    inc a
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