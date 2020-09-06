SECTION "Controls", ROM0
;Gets the current joypad status, compares it to the last joypad status, and writes the press, hold and release states to RAM
GetJoypadStatus:
	push hl
	push bc
	ld hl, rP1
	ld b, %00000000
	
	;Get previous state
	ld a, [joypad_current]
	ld [joypad_last], a
	
	ld [hl], P1F_GET_BTN ; Tell the Game Boy that we want the buttons
	;Get the joypad value, and waste some time so the Game Boy can get the data properly
	ld a, [hl]
	ld a, [hl]
	ld a, [hl]
	ld a, [hl]
	and %00001111 ; Only take the lower 4 bits
	swap a ; swap them with the higher 4 bits
	ld b, a ; then store the result in B
	
	ld [hl], P1F_GET_DPAD ; Tell the Game Boy that we want the DPAD now
	;Get the joypad value, and waste some time so the Game Boy can get the data properly
	ld a, [hl]
	ld a, [hl]
	ld a, [hl]
	ld a, [hl]
	and %00001111 ; Only take the lower 4 bits
	or b ;combine the results together
	cpl ; xor $FF ; flip all bits (normally 1 means idle and 0 means pressed, I want it the other way around)
	ld [joypad_current], a
	
	;Get pressed buttons
	
	; hJoyPressed:  (hJoyLast ^ hJoyInput) & hJoyInput
	ld a, [joypad_last]
	ld b, a
	ld a, [joypad_current]
	xor b
	ld c, a ; store result in c
	ld a, [joypad_current]
	and c
	ld [joypad_pressed], a
	
	; hJoyReleased: (hJoyLast ^ hJoyInput) & hJoyLast
	ld a, [joypad_last]
	ld b, a
	ld a, [joypad_current]
	xor b
	ld c, a ; store result in c
	ld a, [joypad_last]
	and c
	ld [joypad_released], a
	
	pop bc
	pop hl
	ret
;Handles player input and moves the player, shoots bullets, etc
HandleInput:
	;Input
	ld a, [joypad_current] ; Get current joypad state -> B
	;LEFT
	bit J_LEFT, a
	call nz, JoypadLeft
	;RIGHT
	bit J_RIGHT, a
	call nz, JoypadRight
	;DOWN
	bit J_DOWN, a
	call nz, JoypadDown
	;UP
	bit J_UP, a
	call nz, JoypadUp
	;A
	bit J_A, a
	call nz, TryToSpawnBullet

	;Rotate player sprite if not strafing
	ld a, [booleans]
	rra ; bit 0, a
	call nc, GetPlayerSpriteID ; call z, GetPlayerSpriteID

	;Strafe mode toggle
	ld a, [joypad_pressed]
	bit J_SELECT, a
	call nz, ToggleStrafe
	ret

;If the player presses down, move down
JoypadDown:
	push af
	push bc
	call GetMovementSpeed; sets movementSpeed -> B as counter
.loop
	ld a, J_DOWN
	ld [check_direction], a
	call GetCollisionIDInFrontOfPlayer
	call nz, ScrollDown
	dec b
	jr nz, .loop
;end loop
	pop bc
	pop af
	ret

;If the player presses up, move up
JoypadUp:
	push af
	push bc
	call GetMovementSpeed; sets movementSpeed -> B as counter
.loop
	ld a, J_UP
	ld [check_direction], a
	call GetCollisionIDInFrontOfPlayer
	call nz, ScrollUp
	dec b
	jr nz, .loop
;end loop
	pop bc
	pop af
	ret

;If the player presses left, move left
JoypadLeft:
	push af
	push bc
	call GetMovementSpeed; sets movementSpeed -> B as counter
.loop
	ld a, J_LEFT
	ld [check_direction], a
	call GetCollisionIDInFrontOfPlayer
	call nz, ScrollLeft
	dec b
	jr nz, .loop
;end loop
	pop bc
	pop af
	ret
	
;If the player presses right, move right
JoypadRight:
	push af
	push bc
	call GetMovementSpeed; sets movementSpeed -> B as counter
.loop
	ld a, J_RIGHT
	ld [check_direction], a
	call GetCollisionIDInFrontOfPlayer
	call nz, ScrollRight
	dec b
	jr nz, .loop
;end loop
	pop bc
	pop af
	ret

ToggleStrafe:
	ld a, [booleans]
	xor %00000001 ; flip the first bit (strafing = !strafing)
	ld [booleans], a
	ret

;Use the joypad input, check all possible directions to see which way the player is facing. Then update the player object in OAM
GetPlayerSpriteID:
	;UP
	ld a, [joypad_current] ; joypad_current -> A
	and $0F ; mask for only dpad
	ld b, 0 ; B = SPRITE_N
	cp (JF_UP)
	jr z, .done ; goto .done
	;UP RIGHT
	inc b ; B = SPRITE_NE
	cp (JF_UP + JF_RIGHT)
	jr z, .done ; goto .done
	;RIGHT
	inc b ; B = SPRITE_E
	cp (JF_RIGHT)
	jr z, .done ; goto .done
	;DOWN RIGHT
	inc b ; B = SPRITE_SE
	cp (JF_DOWN + JF_RIGHT)
	jr z, .done ; goto .done
	;DOWN
	inc b ; B = SPRITE_S
	cp (JF_DOWN)
	jr z, .done ; goto .done
	;DOWN LEFT
	inc b ; B = SPRITE_SW
	cp (JF_DOWN + JF_LEFT)
	jr z, .done ; goto .done
	;LEFT
	inc b ; B = SPRITE_W
	cp (JF_LEFT)
	jr z, .done ; goto .done
	;TOP LEFT
	inc b ; B = SPRITE_NW
	cp (JF_UP + JF_LEFT)
	jr z, .done ; goto .done
	;If no buttons are pressed:
	ret
.done
	ld a, b
	ld [player_direction], a
	ret

;Get B button, and return either 1 or 2 in reg B
GetMovementSpeed:
	;Check if B button is pressed
	ld a, [joypad_current]
	and JF_B
	or a ; cp 0
	jr nz, .pressed
.notPressed
	;if not pressed (0), return 1
	ld b, 1
	ret
.pressed
	;if pressed (1), return 2
	ld b, 2
	ret