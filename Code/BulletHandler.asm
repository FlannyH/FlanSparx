SECTION "Bullet Handler", ROM0
;Spawn a bullet
;arguments:
;arg1 - direction
TryToSpawnBullet:
    push bc
    push de
    ;See if the timer is ready
    ld a, [bullet_fire_timer]
    ;if it's ready, try to spawn a bullet
    or a ; cp 0
    jr z, .trySpawning
    ;if it's not ready, decrement the counter and exit
    dec a
    ld [bullet_fire_timer], a
    jr .end

.trySpawning
    ;Reset timer
    ld a, [current_fire_rate]
    ld [bullet_fire_timer], a
    ;Find an open spot to fit this bullet in
    ld b, %00100000
    ld a, [active_bullets] ; -> c
    ld c, a
    ld d, 0 ; store the id of the next free slot
.findEmptySpot
    ld a, c
    and b
    jr z, .foundAnEmptySpot ; Spot found? stop loop and use that spot
    inc d
    rr b ; bit shift to the right
    dec a ; cp 1
    jr nz, .findEmptySpot
    ;If no empty spot was found, cancel
    jr .end
    ;Otherwise, continue
.foundAnEmptySpot
    ;Situation: we have the slot id in D, and the slot flag in B
    ;Mark the slot as occupied
    ld a, c ; active_bullets
    or b ; set the slot flag to occupied
    ld [active_bullets], a
.SetAbsolutePosition
    ld hl, bullet_positions
    ld a, d ; apply slot offset, multiply by 2
    rla
    add l
    ld l, a
    CalculateAbsoluteScroll
    ;Write to slot
    ld a, [abs_scroll_y] ; abs_scroll_y -> b
    ld b, a
    ld a, [player_y]
    add 4 ; offset to make it spawn from the middle of the player
    add b ; correct for scroll
    ld [hli], a

    ld a, [abs_scroll_x] ; abs_scroll_x -> b
    ld b, a
    ld a, [player_x]
    add 4 ; offset to make it spawn from the middle of the player
    add b ; correct for scroll
    ld [hli], a
.SetTimer
    ;hl = bullet_life_times + offset
    ld hl, bullet_life_times
    ld a, d
    add l
    ld l, a
    ld [hl], $12
.SetDirection
    ;hl = direction2vector_bullet[player_direction]
    ld hl, direction2vector_bullet 
    ld a, [player_direction]
    rlca ; vector is 2 bytes
    add l
    ld l, a
    ;get x and y
    ld b, [hl]
    inc l
    ld c, [hl]
    ;store it in memory (bullet_directions[offset])as y and x
    ld hl, bullet_directions
    ld a, d
    rlca
    add l
    ld l, a

    ld [hl], c
    inc l
    ld [hl], b

.end
    pop de
    pop bc
    ret

UpdateBulletObjects:
    ;First count down the timer 
    ld a, [bullet_fire_timer]
    or a ; cp 0 ;if timer == 0, don't dec timer, otherwise, do dec timer
    jr z, .dontDecTimer
    dec a
    ld [bullet_fire_timer], a
.dontDecTimer
    ;B - bit flag/counter
    ;C - current ID
    ;HL - shadow oam address of current bullet
    ld b, %00100000
    ld c, 0
.loop
    ld a, [active_bullets] ; active_bullets -> a
    and b ; check one bit
    or a ; cp 0 ; if zero, skip it
    jr z, .skip
    ;otherwise
    
    push bc

;move bullet according to direction
    ;direction yx -> de
    ld hl, bullet_directions ; hl = bullet_directions[2*c]
    ld a, c
    rlca
    add l
    ld l, a
    ld d, [hl]
    inc l
    ld e, [hl]
    ;update position
    ld hl, bullet_positions ; hl = bullet_directions[2*c]
    ld a, c
    rlca
    add l
    ld l, a
    ld a, [hl]
    add d
    ld [hli], a
    ld a, [hl]
    add e
    ld [hl], a

;get oam address of current bullet
    ld hl, sprites_bullets
    ld a, c ; a = c*4
    rlca
    rlca
    add l ; hl += a (no overflow possible here)
    ld l, a
    
;get y coordinate of current bullet
    ld de, bullet_positions
    ld a, c ; a = 2*c
    rlca
    add e
    ld e, a ; e += a (total: e += 2*c)
;subtract abs scroll
    ld a, [abs_scroll_y] ; abs_scroll_y -> B
    ld b, a
    ld a, [de] ; x coordinate -> A
    sub b ; A -= abs_scroll_y
    ld [hli], a

;get x coordinate of current bullet
    ld de, bullet_positions
    ld a, c ; a = 2*c + 1
    rlca
    inc a
    add e
    ld e, a ; e += a (total: e += 2*c)
;subtract abs scroll
    ld a, [abs_scroll_x] ; abs_scroll_x -> B
    ld b, a
    ld a, [de] ; x coordinate -> A
    sub b ; A -= abs_scroll_x
    ld [hli], a
;set sprite tile
    ld [hl], SPRITE_BULLET
    inc l
;set color palette (gameboy classic ignores this attribute)
    ld [hl], 1

;collision detection - input: HL - start of current sprite
    dec l
    dec l
    dec l
    call BulletObjectCollision

    pop bc

;update bullet life time
    ld a, c

    ;hl = bullet_life_times + c (offset)
    ld hl, bullet_life_times 
    add l
    ld l, a
    ;load timer into A
    dec [hl]
    jr nz, .next ; if the timer == 0, set the bullet to inactive, otherwise goto next
    ld a, [active_bullets] ; active_bullets -> l
    xor b ; flip this bit
    ld [active_bullets], a

    jr .next

.skip
;get oam address of current bullet and make the object invisible
    ld hl, sprites_bullets
    ld a, c ; a = c*4
    rlca
    rlca
    add l ; hl += a (no overflow possible here)
    ld l, a
    ld [hl], $00 ; place outside the viewport

.next
    inc c
    or a ; reset carry (unnecessary?)
    rr b ; keep looping until b is 0
    jr nz, .loop
    ld a, c ; get offset to free slot, multiply by 4
    rla
    rla

    ret

SECTION "Bullet Direction LUT", ROM0,ALIGN[4]
direction2vector_bullet:
    db 0, -6 ;N
    db 6, -6 ;NE
    db 6, 0  ;E
    db 6, 6  ;SE
    db 0, 6  ;S
    db -6, 6  ;SW
    db -6, 0  ;W
    db -6, -6  ;NW