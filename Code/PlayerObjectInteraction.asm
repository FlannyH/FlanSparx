SECTION "Player Object Collision", ROM0
PlayerObjectCollision:
    ;Loop through all objects
    ld de, object_table
    ld bc, sprites_objects
    inc e
    .objectLoop
        ld d,d

        ld a, [de] ; Get object type
        push af ; we'll need that later
        ;ld [debug1], a
        
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
        ;ld [debug2], a
        push bc
        ld b, a

        ;get player Y -> A
        ld a, [player_y]
        ;ld [debug3], a
        add 8
        cp a, b ; bul - obj
        jr c, .skipEntry ; if below 0, no collision (if (bul - obj) < 0)
        sub 16+8
        cp a, b ; bul - obj - 16
        jr nc, .skipEntry ; if not below 0, no collision (if (bul - obj) > 16)


        ;get object X -> B
        pop bc
        inc c
        ld a, [bc]
        ;ld [debug2], a
        push bc
        ld b, a

        ;get player X -> A
        inc l
        ld a, [player_x]
        ;ld [debug3], a

        add 8
        cp a, b ; bul - obj
        jr c, .skipEntry ; if below 0, no collision (if (bul - obj) < 0)
        sub 16+8
        cp a, b ; bul - obj - 16
        jr nc, .skipEntry ; if not below 0, no collision (if (bul - obj) > 16)


        ;If we make it all the way here, we're touching the object
        ;do we still have the id somewhere?
        ;no we dont, lets fix that
        pop bc
        pop af

    or a
    rla
    ld b, h
    ld c, l

    ld h, high(PlayerHitObjectSubroutines)
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
        ld [debug4], a
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

        pop af

        jr .objectLoop

SECTION "Player Object Interaction", ROM0, ALIGN[8]
PlayerHitObjectSubroutines:
    dw ObjNone_Update            ; 00 - none
    dw hitByPlayer_Enemy         ; 01 - ObjEnemyStill
    dw PlayerCollision_GemRed    ; 02 - ObjGemRed
    dw PlayerCollision_GemGreen  ; 03 - ObjGemGreen
    dw PlayerCollision_GemBlue   ; 04 - ObjGemBlue
    dw PlayerCollision_GemYellow ; 05 - ObjGemYellow
    dw PlayerCollision_GemPurple ; 06 - ObjGemPurple
    dw hitByPlayer_Enemy         ; 07 - ObjEnemyMove