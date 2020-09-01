;Define variable locations in RAM
    IF !DEF(VARIABLES)
VARIABLES SET 1

;Game variables
camera_x		        EQU $FF88 ;  8 bit
camera_y		        EQU $FF89 ;  8 bit
map_width		        EQU $FF8A ;  8 bit
map_height		        EQU $FF8B ;  8 bit
map_id			        EQU $FF8C ;  8 bit
scroll_x		        EQU $FF8D ;  8 bit
scroll_y		        EQU $FF8E ;  8 bit
player_x		        EQU $FF8F ;  8 bit
player_y		        EQU $FF90 ;  8 bit
player_tile_x	        EQU $FF91 ;  8 bit
player_tile_y	        EQU $FF92 ;  8 bit
abs_scroll_x            EQU $FF93 ;  8 bit
abs_scroll_y            EQU $FF94 ;  8 bit
bullet_fire_timer       EQU $FF95 ;  8 bit
bullet_positions        EQU $C000 ;  12x8 bit (y1, x1, y2, x2, ... ,y8, x8). positions are in the same coordinate space as the scroll registers (bg map)
bullet_directions       EQU $C00C ;  12x8 bit (y1, x1, y2, x2, ... ,y8, x8)
bullet_life_times       EQU $C018 ;  8x8 bit 
current_fire_rate       EQU $FF96 ;  8 bit
booleans                EQU $FF97 ;  8 bit, bit 7 - strafing, 6 - load odd row
current_gem_count       EQU $FFAA ;  8 bit
current_gem_dec1        EQU $FFAB ;  8 bit
current_gem_dec2        EQU $FFAC ;  8 bit
player_health           EQU $FFAD ;  8 bit
objects_destroyed       EQU $C020 ;  256x1 bit (32 bytes)
object_slots_occupied   EQU $C100 ;  Xx8 bits

;Function arguments
tile_detected	    EQU $FF98 ;  8 bit - I use it for tile detection/collision
x_offset		    EQU $FF99 ;  8 bit - I use it for X offset
y_offset		    EQU $FF9A ;  8 bit - I use it for Y offset
check_direction	    EQU $FF9B ;  8 bit
curr_obj_type	    EQU $FF9C ;  8 bit
curr_onscreen_check	EQU $FF9D ;  8 bit
curr_despawn_check	EQU $FFAE ;  8 bit

;Sprites
player_direction    EQU $FF9E
active_bullets      EQU $FF9F ; 8 bits, each bit means if that bullet is active or not

;System state variables
joypad_current	EQU $FFA0 ; 8 bit, right, left, up, down, start, select, b, a
joypad_last		EQU $FFA1 ; 8 bit
joypad_pressed	EQU $FFA2 ; 8 bit
joypad_released	EQU $FFA3 ; 8 bit
gameboy_type    EQU $FFA4 ; 8 bit, $01-GB/SGB, $FF-GBP, $11-GBC
curr_bank       EQU $FFA5 ; 8 bit
music_registers EQU $FFA6 ; 6x8 bit, BC, DE, HL

;Debug variables
frame_counter	EQU $FFF0 ; 8 bit, increases with every VBLANK
debug1          EQU $FFF1
debug2          EQU $FFF2
debug3          EQU $FFF3
debug4          EQU $FFF4
debug5          EQU $FFF5
debug6          EQU $FFF6
debug7          EQU $FFF7
debug8          EQU $FFF8

;Objects
object_table    EQU $D000

;Joypad bits
J_RIGHT         EQU 0
J_LEFT          EQU 1
J_UP            EQU 2
J_DOWN          EQU 3
J_A             EQU 4
J_B             EQU 5
J_SELECT        EQU 6
J_START         EQU 7

;Joypad bits
JF_RIGHT         EQU %00000001
JF_LEFT          EQU %00000010
JF_UP            EQU %00000100
JF_DOWN          EQU %00001000
JF_A             EQU %00010000
JF_B             EQU %00100000
JF_SELECT        EQU %01000000
JF_START         EQU %10000000

;Sprite direction
SPRITE_N    EQU 0
SPRITE_NE   EQU 1
SPRITE_E    EQU 2
SPRITE_SE   EQU 3
SPRITE_S    EQU 4
SPRITE_SW   EQU 5
SPRITE_W    EQU 6
SPRITE_NW   EQU 7

;Sprite names
SPRITE_PLAYER_H1   EQU $00
SPRITE_PLAYER_H2   EQU $02
SPRITE_PLAYER_D1   EQU $04
SPRITE_PLAYER_D2   EQU $06
SPRITE_PLAYER_V1   EQU $08
SPRITE_ENEMY1_H1   EQU $0A
SPRITE_ENEMY1_H2   EQU $0C
SPRITE_ENEMY1_D1   EQU $0E
SPRITE_ENEMY1_D2   EQU $10
SPRITE_ENEMY1_V1   EQU $12
SPRITE_BULLET      EQU $1E
SPRITE_GEM_ROUND   EQU $20
SPRITE_GEM_SQUARE  EQU $22

;Gameboy types
GAMEBOY_REGULAR EQU $01
GAMEBOY_POCKET  EQU $FF
GAMEBOY_COLOR   EQU $11

;Object types
OBJ_NONE        EQU $00
OBJ_GEM         EQU $01

;Tile loading
row_up    EQU 0
row_right EQU 1
row_down  EQU 2
row_left  EQU 3

;ROM banks
set_bank            EQU $2000

;Stack position
stack               EQU $D000

ENDC