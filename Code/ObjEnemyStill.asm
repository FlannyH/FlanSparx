SECTION "ObjEnemyStill", ROM0
;Input: DE - pointer to the 2nd byte of object table entry ([DE] points to the type)
ObjEnemyStill_Update:
    push bc
    push de
    push hl

    ;increase the object array pointer, and store it in hl instead
    inc e
    ld h, d
    ld l, e
    ;The result of the checks will be stored in C as bits
    ;bit 0 - below, 1 - middle, 2 - top, 4 - right, 5 - middle, 6 - left
    ld c, 0

    ;Get if above/below
    .aboveOrBelow
    ld b, [hl] ; B = this.y - 8x8 tile space
    ld a, [camera_y] ; A = player.y - 16x16 tile space
    or a ; bring to 8x8 tile space
    rla
    add 8 ; apply camera offset

    cp b

    jr z, .yMiddle
    jr c, .yAbove
    ;jr nc, .below

    .yBelow
    set 0, c ; set if above
    jr .afterY
    
    .yMiddle
    set 1, c ; set if middle
    jr .afterY

    .yAbove
    set 2, c ; set if below
    ;jr .afterY

    .afterY

    ;Get if left/right
    inc l
    ld b, [hl] ; B = this.x - 8x8
    ld a, [camera_x] ; A = player.x - 16x16
    or a ; 16x16 -> 8x8
    rla 
    add 12 ; apply camera offset

    cp b    

    jr z, .xMiddle
    jr c, .xLeft
    ;jr nc, .below

    .xRight
    set 4, c ; set if right
    jr .afterX
    
    .xMiddle
    set 5, c ; set if middle
    jr .afterX

    .xLeft
    set 6, c ; set if left
    ;jr .afterX

    .afterX
    ;Left
    bit 6, c
    jr nz, .left

    ;Right
    bit 4, c
    jr nz, .right

    ;Otherwise, middle

    .upOrDown                     ; if xMiddle:
    	ld a, 0                   ;     dir = 0
    	bit 0, c                  ;     if down:
    	jr z, .noBottom           ;         //do nothing, dir = 0
    							  ;     else:
    	add 4                     ;         dir = 4
    	.noBottom                 ;
    	jr .afterDirectionCheck   ;
    .left                         ; else if left:
    	ld a, 6                   ;     dir = 6
    	bit 2, c                  ;     if up:
    	jr z, .leftNotUp          ; 
    	inc a              	      ;         inc a
    	.leftNotUp                ;     
    	bit 0, c                  ;     else if down:
    	jr z, .leftNotDown        ;
    	dec a                     ;         dec a
    	.leftNotDown              ;
    	jr .afterDirectionCheck   ;
    							  ;
    .right                        ; else if right:
    	ld a, 2                   ;     dir = 2
    	bit 2, c                  ;     if up:
    	jr z, .rightNotUp         ; 
    	dec a              	      ;         dec a
    	.rightNotUp               ;     
    	bit 0, c                  ;     else if down:
    	jr z, .rightNotDown       ;
    	inc a                     ;         inc a
    	.rightNotDown             ;
    	jr .afterDirectionCheck   ;
	
    .afterDirectionCheck
    ;Set this object's direction to the newly calculated value
    ;HL is currently at the X position in the object table entry ($Dxx3)
    ;The rotation is in $Dxx4
    inc l
    ld [hl], a

    pop hl
    pop de
    pop bc
    ret

;Input: DE - will be loaded as HL, BC - idk yet i'll find out later
DrawSprite_Enemy:
;- Update Sprite
    ld l, e
    ld h, d
    ;Get pointer to this object's direction
    ;High
	push de
    ld a, b
    swap a
    and $0F
    add high(object_table)
    ld d, a

    ;Low
    ld a, b
    swap a
    and $F0
    add 4
    ld e, a

    ;Read direction, and multiply by 4 to get the sprite order offset
    ld a, [de]
    rla
    rla

    ld de, EnemySpriteOrders
    add e
    ld e, a

    ;Finally actually fuckin write the data holy shit it's been 40 lines of preparation until we got here wtf
    
    ;OAM pointer
    ld bc, -4
    add hl, bc

    ;left
    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl+], a
    inc e
    inc l
    inc l
    ;right
    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl], a
    dec l
    pop de
    ret

hitByBullet_Enemy:
    call DeleteObject
    ret

hitByPlayer_Enemy:
    ld a, [player_health]
    dec a
    ld [player_health], a
    call DeleteObject
    ret