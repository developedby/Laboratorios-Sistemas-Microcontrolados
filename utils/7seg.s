SSEG_0	EQU 2_00111111
SSEG_1	EQU 2_00000110
SSEG_2	EQU 2_01011011
SSEG_3	EQU 2_01001111
SSEG_4	EQU 2_01100110
SSEG_5	EQU 2_01101101
SSEG_6	EQU 2_01111101
SSEG_7	EQU 2_00000111
SSEG_8	EQU 2_01111111
SSEG_9	EQU 2_01101111
	
		AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Num_to_7Seg	

; Recebe um numero em r0 e retorna o numero codificado em r0
Num_to_7Seg
	cmp r0, #0
	itt eq
	moveq r0, #SSEG_0
	bxeq lr
	cmp r0, #1
	itt eq
	moveq r0, #SSEG_1
	bxeq lr
	cmp r0, #2
	itt eq
	moveq r0, #SSEG_2
	bxeq lr
	cmp r0, #3
	itt eq
	moveq r0, #SSEG_3
	bxeq lr
	cmp r0, #4
	itt eq
	moveq r0, #SSEG_4
	bxeq lr
	cmp r0, #5
	itt eq
	moveq r0, #SSEG_5
	bxeq lr
	cmp r0, #6
	itt eq
	moveq r0, #SSEG_6
	bxeq lr
	cmp r0, #7
	itt eq
	moveq r0, #SSEG_7
	bxeq lr
	cmp r0, #8
	itt eq
	moveq r0, #SSEG_8
	bxeq lr
	cmp r0, #9
	itt eq
	moveq r0, #SSEG_9
	bxeq lr
	
	b .