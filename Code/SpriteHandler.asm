SECTION "Sprite Handler", ROM0
PrepareSpriteData:
    push de
    push hl
    push bc
    ld de, Sprites ; source
    ld a, bank(Sprites)
    ld [set_bank], a
	ld [curr_bank], a
    ld hl, $8000 ; target
    ld bc, SpritesEnd - Sprites ; length
    call Memcpy
  	call CopyDMARoutine
    pop bc
    pop hl
    pop de
    ret

HandleSprites:
    call HandlePlayerSprite

    ;Copy sprites to OAM
    ld  a, HIGH(wShadowOAM)
    di
    call hOAMDMA
    ei

    ;Flip the half timer
    ld a, [booleans]
    xor (1<<B_HALFTIMER)
    ld [booleans], a

    ret

HandlePlayerSprite:
    push hl
    push bc
    push de
    ;Copy PlayerSpriteOrder into shadow oam
    ;Get the sprite order pointer. sprite orders are aligned to $xx00, so to get the right order, we just take the ID, multiply it by 16, 
    ;then take the high bit of the sprite order pointer
    ;ld a, bank(PlayerSpriteOrders)
    ;ld [set_bank], a
    or a ; clear the carry flag - rla uses the carry flag, this cost me like 20 minutes to fix
    ld a, [player_direction]
    rla  ; a = a * 4
    rla
    rla  ; a = a * 2
    ld de, PlayerSpriteOrders
    add e
    ld e, a
    ;OAM pointer
    ld hl, wShadowOAM
    ld c, 2

.loop
    ;write player_y + order
    ld a, [de]; read
    ld b, a
    ld a, [player_y]
    add b
    ld [hl+], a ; write
    inc e

    ;write player_x + order
    ld a, [de]; read
    ld b, a
    ld a, [player_x]
    add b
    ld [hl+], a ; write
    inc e

    ;write the other 2 bytes
    ld a, [de]; read
    ld [hl+], a ; write
    inc e
    ld a, [de]; read
    ld [hl+], a ; write
    inc e

    dec c
    jr nz, .loop

    pop de
    pop bc
    pop hl
    ret
    

;CREDIT TO https://gbdev.gg8.se/wiki/articles/OAM_DMA_tutorial
SECTION "OAM DMA routine", ROM0
CopyDMARoutine:
  ld  hl, DMARoutine
  ld  b, DMARoutineEnd - DMARoutine ; Number of bytes to copy
  ld  c, LOW(hOAMDMA) ; Low byte of the destination address
.copy
  ld  a, [hl+]
  ldh [c], a
  inc c
  dec b
  jr  nz, .copy
  ret

DMARoutine:
  ldh [rDMA], a
  
  ld  a, 40
.wait
  dec a
  jr  nz, .wait
  ret
DMARoutineEnd:

SECTION "OAM DMA", HRAM

hOAMDMA::
  ds DMARoutineEnd - DMARoutine ; Reserve space to copy the routine to

SECTION "Shadow OAM", WRAM0[$C500],ALIGN[8]

wShadowOAM:
sprites_player: ds 2*4 ; 2/40 - total 2/40
sprites_bullets: ds 6*4 ; 8/40 - total 8/40
sprites_objects: ds 32*4 ; 32/40 - total 40/40

SECTION "PlayerSpriteOrders", ROM0,ALIGN[6]
PlayerSpriteOrders:
PlayerSpriteOrderN:
    db $00, $00, SPRITE_PLAYER_V1, $00 ;Y, X, Tile ID, attributes
    db $00, $08, SPRITE_PLAYER_V1, $20
PlayerSpriteOrderNE:
    db $00, $00, SPRITE_PLAYER_D1, $00
    db $00, $08, SPRITE_PLAYER_D2, $00
PlayerSpriteOrderE:
    db $00, $00, SPRITE_PLAYER_H1, $00
    db $00, $08, SPRITE_PLAYER_H2, $00
PlayerSpriteOrderSE:
    db $00, $00, SPRITE_PLAYER_D1, $40
    db $00, $08, SPRITE_PLAYER_D2, $40
PlayerSpriteOrderS:
    db $00, $00, SPRITE_PLAYER_V1, $40 ; $40 - Y flip
    db $00, $08, SPRITE_PLAYER_V1, $60
PlayerSpriteOrderSW:
    db $00, $08, SPRITE_PLAYER_D1, $60 ; $60 - Y flip + X flip
    db $00, $00, SPRITE_PLAYER_D2, $60
PlayerSpriteOrderW:
    db $00, $08, SPRITE_PLAYER_H1, $20 ; $20 - X flip
    db $00, $00, SPRITE_PLAYER_H2, $20
PlayerSpriteOrderNW:
    db $00, $08, SPRITE_PLAYER_D1, $20 ; $20 - X flip
    db $00, $00, SPRITE_PLAYER_D2, $20

SECTION "Enemy1SpriteOrders", ROM0,ALIGN[6]
EnemySpriteOrders:
EnemySpriteOrderN:
    db SPRITE_ENEMY1_V1, $02 ;Y, X, Tile ID, attributes
    db SPRITE_ENEMY1_V1, $22
EnemySpriteOrderNE:
    db SPRITE_ENEMY1_D1, $02
    db SPRITE_ENEMY1_D2, $02
EnemySpriteOrderE:
    db SPRITE_ENEMY1_H1, $02
    db SPRITE_ENEMY1_H2, $02
EnemySpriteOrderSE:
    db SPRITE_ENEMY1_D1, $42
    db SPRITE_ENEMY1_D2, $42
EnemySpriteOrderS:
    db SPRITE_ENEMY1_V1, $42 ; $40 - Y flip
    db SPRITE_ENEMY1_V1, $62
EnemySpriteOrderSW:
    db SPRITE_ENEMY1_D2, $62
    db SPRITE_ENEMY1_D1, $62 ; $60 - Y flip + X flip
EnemySpriteOrderW:
    db SPRITE_ENEMY1_H2, $22
    db SPRITE_ENEMY1_H1, $22 ; $20 - X flip
EnemySpriteOrderNW:
    db SPRITE_ENEMY1_D2, $22
    db SPRITE_ENEMY1_D1, $22 ; $20 - X flip

SECTION "Gem Sprite Orders", ROM0, ALIGN[4]
GemRed:
    db SPRITE_GEM_ROUND, $03
    db SPRITE_GEM_ROUND, $23
GemGreen:
    db SPRITE_GEM_ROUND, $04
    db SPRITE_GEM_ROUND, $24
GemBlue:
    db SPRITE_GEM_SQUARE, $05
    db SPRITE_GEM_SQUARE, $25
GemYellow:
    db SPRITE_GEM_SQUARE, $06
    db SPRITE_GEM_SQUARE, $26
GemPurple:
    db SPRITE_GEM_ROUND, $07
    db SPRITE_GEM_ROUND, $27