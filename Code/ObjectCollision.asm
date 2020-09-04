SECTION "Objects Collision", ROM0
;Input: HL - start of current bullet sprite
BulletObjectCollision:
    ;Loop through all objects
    ld de, object_table
    ld bc, sprites_objects
    inc e
    .objectLoop
        ld d,d

        ld a, [de] ; Get object type
        push af ; we'll need that later
        
        or a ; cp $00 - none type
        jr z, .endLoop
        cp $FF ;- none type
        jr z, .skipBecauseNoneType
        ;Move to on screen check variable
        inc e
        inc e
        inc e
        inc e
        ld a, [de]
        or a ; cp $00 - if not on screen
        jr z, .skipBecauseNoneType
        dec e
        dec e
        dec e
        dec e


        ;otherwise
        ld d,d
        ;get object Y -> B
        ld a, [bc]
        push bc
        ld b, a

        ;get bullet Y -> A
        ld a, [hl]

        cp a, b ; bul - obj
        jr c, .skipEntry ; if below 0, no collision (if (bul - obj) < 0)
        sub 16
        cp a, b ; bul - obj - 16
        jr nc, .skipEntry ; if not below 0, no collision (if (bul - obj) > 16)


        ;get object X -> B
        pop bc
        inc c
        ld a, [bc]
        push bc
        ld b, a

        ;get bullet X -> A
        inc l
        ld a, [hl]


        cp a, b ; bul - obj
        jr c, .skipEntry ; if below 0, no collision (if (bul - obj) < 0)
        sub 16
        cp a, b ; bul - obj - 16
        jr nc, .skipEntry ; if not below 0, no collision (if (bul - obj) > 16)


        ;If we make it all the way here, we hit the object
        ;do we still have the id somewhere?
        ;no we dont, lets fix that
        pop bc
        pop af

    or a
    rla
    ld b, h
    ld c, l

    ld h, high(BulletHitObjectSubroutines)
    ld l, a ; ObjectSubroutines is aligned, so no ADD required

    ;Load the subroutine pointer into HL
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    
    ;Run the subroutine
    call RunSubroutine
    ret

    .endLoop
        pop af
        ret
    .skipEntry
        ld a, 0
        ld [debug1], a
        pop bc

        ;OAM - Snap to start of entry, and add 8 to go to the next object (1 object = 2 sprite, 1 sprite = 4 bytes)
        ld a, c
        and %11111000 ; Snap to 8 (eg 0, 8, 16, ...)
        add 8
        ld c, a
    .skipBecauseNoneType

        ;OBJECT TABLE - Snap to start of entry, and add 16 to go to next
        ld a, e
        and %11110000 ; Snap to 4 (eg 0, 4, 8, ...)
        add 16
        ld e, a
        ld a, d
        adc 0 ; handle overflow
        ld d, a
        inc e ; Move to the enemy type

        ;BULLET SPRITE POINTER - Snap to start of entry (snap to 8 bytes)
        ld a, l
        and %11111100
        ld l, a

        pop af

        jr .objectLoop

;Input: HL - OAM pointer to bullet
deleteCurrentBullet:
        ;Delete this bullet
        ;First we need the bullet index, so we can set the timer to 0
        ;To get the bullet index, we can reuse the pointer to OAM
        push hl
        ld a, l
        sub 1+low(sprites_bullets); move to the start of the entry, then subtract 8 more, since bullets start at $C508
        ;Each OAM entry is 4 bytes, so bit shift time
        rra
        rra
        and %00111111 ; no overflow allowed
        add low(bullet_life_times) ; go to the right offset
        ld h, high(bullet_life_times)
        ld l, a
        ld a, $01 ;write $01 to this bullet's timer, deleting it the next frame
        ld [hl], a
        pop hl
        ret

;Input: DE - at object_table.current_object.type
DeleteObject:
    pop hl
    ;Clear object_table entry
    ld a, $FF ; clear this slot's type
    ld [de], a
    dec e
    ld a, [de] ; read object id and store it for later
    push af ; we'll need this value later
    ld a, $FF ; clear this slot's ID
    ld [de], a

    ;Clear object_slots_occupied entry
    ;To get the object index, I take the object table pointer, for example $D130
    ;Remove the object_table offset ($D000): $D130 - $D000 = $0130
    push de
    ld a, d
    sub high(object_table)
    ;Add the 2 bytes together: $01(d) + $30(e) = $31
    add e
    ;Then swap the 2 nibbles: $31 -> $13, and then you have the index
    swap a
    ld e, a
    ;Just set the high byte to $C6 next, so we're actually in the object_slots_occupied array
    ld d, high(object_slots_occupied)
    ;Clear it
    ld a, $FF
    ld [de], a

    ld h, b
    ld l, c

    call deleteCurrentBullet
    pop de
    pop af ; retrieve the object index -> A
    call SetObjectDestroyed

    ;Then return from this subroutine
    ret

;Input: A - object id
SetObjectDestroyed:
    push de
    push hl
    dec a ; ids start at $01, move to $00
    ;Get memory location in bits and bytes
    ld d, a
    and %00000111
    ld e, a ; store the bit number in E

    ;get A back, so we can get the bit
    ld a, d
    rra
    rra
    rra
    and %00011111 ; make sure no carry bits came through

    ;get the pointer to the right byte
    ld hl, objects_destroyed
    add l
    ld l, a

    ;get the right bitmask
    ld a, e
    ld d, %10000000 ;start from the left
    .bitmaskLoop
        or a ; cp 0 - if the counter is 0, stop the loop, also reset the carry flag
        jr z, .endLoop
        ;otherwise
        rr d
        dec a
        jr .bitmaskLoop

    .endLoop

    ;Now we have the bitmask, let's set the value in the array to 1
    ld a, [hl]
    or d
    ld [hl], a

    ld d, d

    ;Decrease object count
    ld hl, curr_enemy_count
    dec [hl]

    call CleanObjectTable

    pop hl
    pop de
    ret

;Input: A - object ID, Output: - A - 0=no, anything else=yes
IsThisObjectDestroyed:
    push de
    push hl
    dec a ; ids start at $01, move to $00
    ;Get memory location in bits and bytes
    ld d, a
    and %00000111
    ld e, a ; store the bit number in E

    ;get A back, so we can get the bit
    ld a, d
    rra
    rra
    rra
    and %00011111 ; make sure no carry bits came through

    ;get the pointer to the right byte
    ld hl, objects_destroyed
    add l
    ld l, a

    ;get the right bitmask
    ld a, e
    ld d, %10000000 ;start from the left
    .bitmaskLoop
        or a ; cp 0 - if the counter is 0, stop the loop, also reset the carry flag
        jr z, .endLoop
        ;otherwise
        rr d
        dec a
        jr .bitmaskLoop

    .endLoop

    ;Now we have the bitmask, let's see what this bit is
    ld a, [hl]
    and d

    pop hl
    pop de
    ret

SECTION "Bullet Object Interaction", ROM0, ALIGN[8]
BulletHitObjectSubroutines:
    dw ObjNone_Update    ; 00 - none
    dw hitByBullet_Enemy ; 01 - ObjEnemyStill
    dw ObjNone_Update    ; 02 - ObjGemRed
    dw ObjNone_Update    ; 03 - ObjGemGreen
    dw ObjNone_Update    ; 04 - ObjGemBlue
    dw ObjNone_Update    ; 05 - ObjGemYellow
    dw ObjNone_Update    ; 06 - ObjGemPurple
    dw hitByBullet_Enemy ; 07 - ObjEnemyMove