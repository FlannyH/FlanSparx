SECTION "User Interface", ROM0
;Update the tiles on the window layer for the gem count and health bar
UpdateHUD:
    push hl

    ;Display gem icon
    ld hl, _SCRN1 ; Window tile data
    inc l
    ld [hl], $7E ; Gem icon
    inc l

    ;Update gem count
    ;Left digit
    ld a, [current_gem_dec1]
    add $74
    ld [hl+], a

    ;Middle digit
    ld a, [current_gem_dec2]
    swap a
    and $0F ; Get the high nibble
    add $74
    ld [hl+], a

    ;Right digit
    ld a, [current_gem_dec2]
    and $0F ; Get the low nibble
    add $74 ; that's where the number tiles start
    ld [hl+], a

    ;Display health icon
    ld l, $0E
    ld [hl], $73 ; health icon
    inc l

    ;Display health bar
    ld a, [player_health]
    ;first tile
    cp 2
    call nc, .full
    cp 1
    call z, .half
    call c, .empty

    inc l

    ;second tile
    cp 4
    call nc, .full
    cp 3
    call z, .half
    call c, .empty

    inc l

    ;second tile
    cp 6
    call nc, .full
    cp 5
    call z, .half
    call c, .empty


    pop hl
    ret

    .full
        ld [hl], $70
        ret
    .half
        ld [hl], $71
        ret
    .empty
        ld [hl], $72
        ret