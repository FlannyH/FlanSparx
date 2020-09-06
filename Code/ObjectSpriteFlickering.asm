SECTION "Object Sprite Flickering", ROM0
;If there are 4 or more enemies on the same scanline, start flickering
CheckIfFlickeringNecessary:
    push hl
    ld h, high(object_table)
    ld l, 1 ; we need the id and the y position
    ld c, $FF ; set C to the max
    ld de, 16 ; amount to add to HL after each loop cycle

.findLowestYLoop
    ;Check if valid ID
    ld a, [hl+] ; load id
    or a ; cp 0
    jr z, .endLowestYLoop
    inc a ; cp $ff
    jr z, .goToNextEntry

    ld b, [hl] ; load the current Y coordinate

    ;Check if this object is on screen
    inc l
    inc l
    inc l
    ld a, [hl] ; check if on screen
    or a ; cp 0 ; if 0, object is not on screen
    jr z, .goToNextEntry

    ;Object is on screen
    ld a, c ; current min
    cp b
    jr c, .dontSetAsMinimum

    ;This object is the lowest
    ld c, b

    .dontSetAsMinimum

    .goToNextEntry
    ;Move to next entry, and make sure it's at the ID
    ld a, l
    and $F0
    or 1
    ld l, a
    add hl, de
    jr .findLowestYLoop

.endLowestYLoop
    ld a, c
    ld [debug3], a

.CheckEveryPossibleScanline
    call GetCurrentYcoordinateCount
    ;If there are 4 objects on 1 scanline, there are 8 sprites on that scanline, which can be 10 if the player's there too
    ;To make sure every object is visible, enable flickering when there are 5 or more on one line
    ld a, b
    cp 5
    jr nc, .enableSpriteFlickering

    call GetNextLowestScanline
    ld a, c
    inc a
    or a ; cp 0
    jr nz, .CheckEveryPossibleScanline
.endOfSubroutine
    ld hl, booleans
    res B_FLICKERSPRITES, [hl]
    pop hl
    ret
.enableSpriteFlickering
    ld hl, booleans
    set B_FLICKERSPRITES, [hl]
    pop hl
    ret

;Count the amount of objects with this y tile coordinate
;Input: C - tile y coordinate to compare with, Output: B - object count
GetCurrentYcoordinateCount:
    ld h, high(object_table)
    ld l, 1
    ld b, 0 ; object count on this y coordinate
    ld de, 16 ; amount to add to hl after every loop

.getCountLoop
    ;Check if valid type
    ld a, [hl+] ; load type, and move to y coordinate
    or a ; cp 0
    jr z, .endCurrentYloop
    inc a ; cp $ff
    jr z, .dontIncrement

    ;get the tile y coordinate. is it the same as the one we're looking for? increase B
    ld a, [hl] ; load y coordinate
    cp c ; if it's the same as the one we compare with, increment B
    jr nz, .dontIncrement

    inc b

    .dontIncrement
    dec l
    add hl, de
    jr .getCountLoop

    .endCurrentYloop
    ld a, b
    ld [debug4], a
    ret

;Input: C - current tile y coordinate, Output: C - next tile y coordinate
GetNextLowestScanline:
    ld h, high(object_table)
    ld l, 1 ; we need the id and the y position
    ld d, c ; store the current tile y coordinate
    ld c, $FF ; set C to the max

.findLowestYLoop
    ;Check if valid ID
    ld a, [hl+] ; load id
    or a ; cp 0
    jr z, .endLowestYLoop
    inc a ; cp $ff
    jr z, .goToNextEntry

    ld b, [hl] ; load the current Y coordinate

    ;Check if this object is on screen
    inc l
    inc l
    inc l
    ld a, [hl] ; check if on screen
    or a ; cp 0 ; if 0, object is not on screen
    jr z, .goToNextEntry

    ;Object is on screen
    ld a, c ; current min
    cp b
    jr c, .dontSetAsMinimum
    
    ;Make sure the new minimum isn't lower than the previous minimum
    ld a, b
    cp d
    jr c, .dontSetAsMinimum

    ;This object is the lowest
    ld c, b

    .dontSetAsMinimum

    .goToNextEntry
    ;Move to next entry, and make sure it's at the ID
    ld a, l
    and $F0
    or 1
    ld l, a

    push de 
    ld de, 16 ; amount to add to HL after each loop cycle
    add hl, de
    pop de
    jr .findLowestYLoop

.endLowestYLoop
    ld a, d
    cp b
    jr nz, .dontFlagAsDone

    ld b, $ff ; if the tile y didnt change, end the loop, we're at the end

    .dontFlagAsDone

    ld c, b
    ld a, c
    ld [debug5], a
    ret

;Hide one half of the sprite one frame, then the other one frame, repeat
HandleSpriteFlickering:
    push hl

    ;Only flicker if necessary
    ld hl, booleans
    bit B_FLICKERSPRITES, [hl]
    jr z, .end

    ;If flickering is necessary, set every other sprite entry in the OAM to have a Y coordinate of 0, hiding them
    ;Do all the left sprites one frame, then do all the right sprite another frame
    ld a, [hl] ; booleans
    and (1 << B_HALFTIMER) ; this sets A to 0 if left sprites, and to 32 if right sprites
    ;Since an OAM entry is 4 bytes, we need to divide by 8
    or a
    rra
    rra
    rra
    rra
    ;Load the pointer to shadow OAM, and add the offset
    ld hl, sprites_objects
    add l
    ld l, a

    ld b, 16 ; amount of objects to handle
    ld de, 8 ; amount to add to HL after one loop (basically move to next object)

    .hidingLoop
        ld [hl], 0
        add hl, de
        dec b
        jr nz, .hidingLoop

.end 
    pop hl
    ret

;Writes an object into OAM, getting the position and direction from RAM
;Input:
; DE 
WriteSpriteButFlickering:
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