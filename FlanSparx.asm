INCLUDE "Code/hardware.inc"
INCLUDE "Code/Variables.asm"
INCLUDE "Code/MiscFunctions.asm"
INCLUDE "Code/TilemapLoader.asm"
INCLUDE "Code/Controls.asm"
INCLUDE "Code/SpriteHandler.asm"
INCLUDE "Code/Resources.asm"
INCLUDE "Code/Collision.asm"
INCLUDE "Code/BulletHandler.asm"
INCLUDE "Code/Init.asm"
INCLUDE "Code/TitleScreen.asm"
INCLUDE "Code/Objects.asm"
INCLUDE "Code/WaveMusic.asm"
INCLUDE "Code/ObjectCollision.asm"
INCLUDE "Code/PlayerObjectInteraction.asm"
INCLUDE "Code/UserInterface.asm"

SECTION "Header", ROM0[$100]

EntryPoint: ; Program start
	di; Disable interrupts
	jp Start;
	
REPT $150 - $104
    db 0
ENDR

SECTION "Game code", ROM0
Start:
	call Init
	;spawn the level objects
	ld de, objects_level_test
	call WaveStart
	call GameLoop

GameLoop:
	ei
	call GetJoypadStatus
	call HandleInput
	call HandleSprites
	call UpdateBulletObjects
	call UpdateBulletCollision
	call PlayerObjectCollision

    call UpdateObjectOAM
	
	call CheckObjectsOnScreen
	call CheckObjectsOnScreen
	call CheckObjectsOnScreen
	call CheckObjectsOnScreen
	call CheckObjectsOnScreen

	call waitVBlank
	call UpdateHUD

	jr GameLoop
	ret
