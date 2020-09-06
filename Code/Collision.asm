SECTION "Collision Detection", ROM0
;Gets the tile ID of the tile in front of the player
GetCollisionIDInFrontOfPlayer:
    push hl
    push bc
    push de

    call CalculateCollisionDetectionOffset


    ;Get player tile X position
    ld a, [player_x] ; player_x -> b
    add 16
    ld b, a
    ld a, [abs_scroll_x] ; camera_x -> a
    add b ; a += b
    add d ; x offset
    
    or a ; reset carry flag
    rra
    rra
    rra
    and %00011111 ; remove any potential carry bits that got through
    ld [player_tile_x], a

    ;Get player tile Y position
    ld a, [player_y] ; player_y -> b
    add 8
    ld b, a
    ld a, [abs_scroll_y] ; camera_y -> a
    add b ; a += b
    add e ; y offset

    srl a
    srl a
    srl a
    ld [player_tile_y], a

    ;Get tile in position (player_tile_x, player_tile_y)
    ld a, [player_tile_y] ; player_tile_y -> de
    ld d, $00
    ld e, a
    or a ; reset c flag
    ; e is in range $00 - $1F, first 3 bit shifts can be done without D
    rl e
    rl e
    rl e
    rl e
    rl d
    rl e
    rl d
    ld a, [player_tile_x] ; add player_tile_x to de
    add e
    ld e, a
    ;We now have the tile offset in DE, let's add the vram offset to it now
    ld a, $98 ; $9800 is BG map start
    add d ; add it to D
    ld d, a
    ;DE - VRAM offset
    ;let's read the tile and use it to get the tile attribute
    waitForRightVRAMmode

    ld a, [de]
    ld [tile_detected], a
    call GetTilemapAttribute ; -> A
    dec a ; cp 1 ; -> output
    pop de
    pop bc
    pop hl
    ret

;Apply offset (x->d y->e) so it actually checks in front of the player, and not exactly where the player is
CalculateCollisionDetectionOffset:
;RESET DE
    ld de, $0000
;X OFFSET
    push af
    ld a, [check_direction] ; 0 - right, 1 - left
    or a ; cp 0 ; if right
    jr nz, .notRight
    ld d, 8 ; offsets are finetuned based on the sprite
    jr .notLeft
.notRight
    dec a ; cp 1 ; if left
    jr nz, .notLeft
    ld d, -8
.notLeft

;Y OFFSET
    ;Apply offset so it actually checks in front of the player, and not exactly where the player is
    ld a, [check_direction] ; 2 - up, 3 - down
    cp 2 ; if up
    jr nz, .notUp
    ld e, -8
    jr .notDown
.notUp
    cp 3 ; if down
    jr nz, .notDown
    ld e, 8
.notDown
    pop af
    ret

;input: tile_detected - tile id
;output: reg A - tile attribute
GetTilemapAttribute:
    push hl
    ;tile_detected -> a, TileAttributes -> hl
    ld a, [tile_detected]
    ld hl, TileAttributes
    ;hl += a
    add l
    ld l, a
    ;load bank
	ld a, bank(TileAttributes)
	ld [set_bank], a
	ld [curr_bank], a
    ld a, [hl]
    pop hl
    ret

UpdateBulletCollision:
    ;b - bit mask
    ;c - current id
    ;d - active_bullets
    ;hl - pointer to current bullet's position
    ld b, %00100000
    ld c, 0
    ld a, [active_bullets]
    ld d, a
    ld hl, bullet_positions
.loop
    ld a, d ; active_bullets -> a
    and b ; current bit
    or a ; cp 0 ; is it 0?
    jr z, .skip ; if so, skip this one
    ;otherwise, continue
    push de
    push bc
    ;load y into de, x into b
    ld d, $00
    ld e, [hl]
    inc l
    ld a, [hl]
    add 8
    ld b, a
    inc l
    ;shift y to the left twice, and then mask the lower 5 bits out (to make it just the y component)
    rl e
    rl d    
    rl e
    rl d
    ld a, e
    and %11100000
    ;shift b to the right 3 times (from $00 - $ff to $00 - $1f)
    or a;
    rr b
    or a;
    rr b
    or a;
    rr b
    ;then add b
    add b
    ld e, a
    ;then add $98 to d
    ld a, d
    add $98
    ld d, a
    ;DE is now a pointer to a background tile, let's read and decode it
    pop bc
    ;vram might be locked, make sure it isn't first
    waitForRightVRAMmode

    ld a, [de]
    ld [tile_detected], a
    call GetTilemapAttribute ; -> reg A
    ;If it's a wall, delete the bullet by setting the timer to 0
    dec a ; cp 1
    jr nz, .noWall ; don't do it if it's not a wall

    ;get pointer to current timer
    ld de, bullet_life_times
    ld a, e
    add c
    ld e, a
    ld a, 1
    ;set timer to 1
    ld [de], a

.noWall
    pop de
    jr .next

.skip
    ;since we dont use this bullet's position, skip it
    inc l
    inc l
.next
    ;dec counters
    sra b ; b = b >> 1
    
    inc c
    ld a, c
    cp 6
    jr nz, .loop
    ret

SECTION "Tile Attributes", ROMX,ALIGN[8] ; align so the code is more efficient (remove any overflows, so code doesn't have to take it into account at all)
TileAttributes:
;    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0
;    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0
;    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0
;    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0
;    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0
;    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0
;    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0
;    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0

    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    1, 1, 1, 1,    1, 1, 1, 1,    1, 1, 1, 1,    1, 1, 1, 1    
    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    1, 1, 1, 1,    1, 1, 1, 1,    1, 1, 1, 1,    1, 1, 1, 1    
    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    1, 1, 1, 1,    1, 1, 1, 1,    1, 1, 1, 1,    1, 1, 1, 1    
    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    1, 1, 1, 1,    1, 1, 1, 1,    1, 1, 1, 1,    1, 1, 1, 1    
    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    1, 1, 1, 1,    1, 1, 1, 1,    1, 1, 1, 1    
    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    1, 1, 1, 1,    1, 1, 1, 1,    1, 1, 1, 1    
    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    1, 1, 1, 1,    1, 1, 1, 1,    1, 1, 1, 1    
    db 0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0,    0, 0, 0, 0