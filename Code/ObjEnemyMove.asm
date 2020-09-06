SECTION "ObjEnemyMove", ROM0
;Input: DE - pointer to the 2nd byte of object table entry ([DE] points to the type)
;Modifies all registers
ObjEnemyMove_Update:
    call ObjEnemyStill_Update ; reuse the stationary enemy code
    ;ObjEnemyStill_Update leaves the direction in register A
    ;Use this to your advantage
    ld hl, booleans
    bit B_HALFTIMER, [hl]
    ret nz ; only move every other frame, this makes them move at half speed

    ;Turn direction into array offset
    or a
    rla

    ;Load the lookup table and add the offset
    ld hl, direction2vector_obj
    add l
    ld l, a

    ;Get the amount of pixels to move in each axis
    ld b, [hl]
    inc l
    ld c, [hl]

    ;DE still contains the pointer to the object table entry, though it's at byte 1 (type), we need byte 6 and 7 (fine position)
    ld a, e
    add 5
    ld e, a

    ;Y position
    ld a, [de]
    add b

    ;Check if it's time to increase/decrease the tile position yet
    cp 8
    jr z, .incY

    cp -8
    jr z, .decY

    jr .noY

    .incY
        ;Increase Y tile position
        rept 4
           dec e  
        endr

        ld a, [de]
        inc a
        ld [de], a

        rept 4
           inc e  
        endr

        xor a ; ld a, 0 ; value to reset fine position to

        jr .noY
    .decY
        ;Decrease Y tile position
        rept 4
           dec e  
        endr

        ld a, [de]
        dec a
        ld [de], a

        rept 4
           inc e  
        endr

        xor a ; ld a, 0 ; value to reset fine position to
        ;jr .noY
    .noY
    
    ld [de], a ; write the new fine position

    inc e

    ;X position
    ld a, [de]
    add c

    ;Check if it's time to increase/decrease the tile position yet
    cp 8
    jr z, .incX

    cp -8
    jr z, .decX

    jr .noX

    .incX
        ;Increase Y tile position
        rept 4
           dec e  
        endr

        ld a, [de]
        inc a
        ld [de], a

        rept 4
           inc e  
        endr

        xor a ; ld a, 0 ; value to reset fine position to

        jr .noX
    .decX
        ;Decrease Y tile position
        rept 4
           dec e  
        endr

        ld a, [de]
        dec a
        ld [de], a

        rept 4
           inc e  
        endr

        xor a ; ld a, 0 ; value to reset fine position to
        ;jr .noX
    .noX
    
    ld [de], a ; write the new fine position

    ;Return the pointer to where it was
    ld a, e
    sub 6
    ld e, a

    ret


SECTION "Object Move Direction LUT", ROM0,ALIGN[4]
direction2vector_obj:
    db -1,  0  ;N
    db -1,  1  ;NE
    db  0,  1  ;E
    db  1,  1  ;SE
    db  1,  0  ;S
    db  1, -1  ;SW
    db  0, -1  ;W
    db -1, -1  ;NW