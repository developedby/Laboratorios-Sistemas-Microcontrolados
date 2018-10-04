; main.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 15/03/2018
; Este programa espera o usuário apertar a chave USR_SW1 e/ou a chave USR_SW2.
; Caso o usuário pressione a chave USR_SW1, acenderá o LED2. Caso o usuário pressione 
; a chave USR_SW2, acenderá o LED1. Caso as duas chaves sejam pressionadas, os dois 
; LEDs acendem.

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declarações EQU - Defines
;<NOME>         EQU <VALOR>
; ========================
; Definições de Valores
BIT0	EQU 2_0001
BIT1	EQU 2_0010
	
DISPLAY_UNIDADE EQU 0
DISPLAY_DEZENA 	EQU 1
LEDS 			EQU 2

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



; -------------------------------------------------------------------------------
; Área de Dados - Declarações de variáveis
		AREA  DATA, ALIGN=2
		; Se alguma variável for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a variável <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma variável de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posição da RAM		

; -------------------------------------------------------------------------------
; Área de Código - Tudo abaixo da diretiva a seguir será armazenado na memória de 
;                  código
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma função do arquivo for chamada em outro arquivo	
        EXPORT Start                ; Permite chamar a função Start a partir de 
			                        ; outro arquivo. No caso startup.s
									
		; Se chamar alguma função externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma 
									; função <func>
		IMPORT  GPIO_Init
        IMPORT  PortJ_Input
		IMPORT	PLL_Init
		IMPORT	SysTick_Init
		IMPORT	SysTick_Wait1ms
		IMPORT	GPIO_PORTA_AHB_DATA_R
		IMPORT	GPIO_PORTB_AHB_DATA_R
		IMPORT	GPIO_PORTJ_AHB_DATA_R
		IMPORT	GPIO_PORTM_AHB_DATA_R
		IMPORT	GPIO_PORTQ_AHB_DATA_R
; -------------------------------------------------------------------------------

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

; Função main()
Start  			
	BL PLL_Init                  ;Chama a subrotina para alterar o clock do microcontrolador para 80MHz
	BL SysTick_Init              ;Chama a subrotina para inicializar o SysTick
	BL GPIO_Init                 ;Chama a subrotina que inicializa os GPIO

	mov r5, #1
	mov r6, #0
	mov r7, #DISPLAY_UNIDADE
	mov r8, #0
	mov r9, #0
	mov r10, #0
	mov r11, #0
	mov r12, #0
	b Multiplexa
MainLoop
Multiplexa
	cmp r7, #DISPLAY_UNIDADE
	beq Mux_Unidades
	cmp r7, #DISPLAY_DEZENA
	beq Mux_Dezenas
	cmp r7, #LEDS
	beq Mux_Leds
	b .

Mux_Unidades
	LDR	R1, =GPIO_PORTB_AHB_DATA_R		    
	LDR R2, [R1]
	BIC R2, #2_00110000                     
	mov r0, #2_00100000
	ORR R0, R0, R2                          
	STR R0, [R1]
	
	LDR	R1, =GPIO_PORTM_AHB_DATA_R		    
	LDR R2, [R1]
	BIC R2, #2_01000000                    
	mov r0, #2_00000000
	ORR R0, R0, R2                          
	STR R0, [R1]
	mov r7, #DISPLAY_DEZENA
	mov r0, r8
	b Escreve_Digito
Mux_Dezenas
	LDR	R1, =GPIO_PORTB_AHB_DATA_R		    
	LDR R2, [R1]
	BIC R2, #2_00110000                     
	mov r0, #2_00010000
	ORR R0, R0, R2                          
	STR R0, [R1]
	
	LDR	R1, =GPIO_PORTM_AHB_DATA_R		    
	LDR R2, [R1]
	BIC R2, #2_01000000                    
	mov r0, #2_00000000
	ORR R0, R0, R2                          
	STR R0, [R1]
	mov r7, #LEDS
	mov r0, r9
	b Escreve_Digito
Mux_Leds
	LDR	R1, =GPIO_PORTB_AHB_DATA_R		    
	LDR R2, [R1]
	BIC R2, #2_00110000                     
	mov r0, #2_00000000
	ORR R0, R0, R2                          
	STR R0, [R1]
	
	LDR	R1, =GPIO_PORTM_AHB_DATA_R		    
	LDR R2, [R1]
	BIC R2, #2_01000000                    
	mov r0, #2_01000000
	ORR R0, R0, R2                          
	STR R0, [R1]
	mov r7, #DISPLAY_UNIDADE
	b Escolhe_Led
Escolhe_Led
	cmp r10, #0
	itt eq
	moveq r0, #2_10000000
	beq Escreve_Led
	cmp r10, #1
	itt eq
	moveq r0, #2_01000000
	beq Escreve_Led
	cmp r10, #2
	itt eq
	moveq r0, #2_00100000
	beq Escreve_Led
	cmp r10, #3
	itt eq
	moveq r0, #2_00010000
	beq Escreve_Led
	cmp r10, #4
	itt eq
	moveq r0, #2_00001000
	beq Escreve_Led
	cmp r10, #5
	itt eq
	moveq r0, #2_00000100
	beq Escreve_Led
	cmp r10, #6
	itt eq
	moveq r0, #2_00000010
	beq Escreve_Led
	cmp r10, #7
	itt eq
	moveq r0, #2_00000001
	beq Escreve_Led
	cmp r10, #8
	itt eq
	moveq r0, #2_00000010
	beq Escreve_Led
	cmp r10, #9
	itt eq
	moveq r0, #2_00000100
	beq Escreve_Led
	cmp r10, #10
	itt eq
	moveq r0, #2_00001000
	beq Escreve_Led
	cmp r10, #11
	itt eq
	moveq r0, #2_00010000
	beq Escreve_Led
	cmp r10, #12
	itt eq
	moveq r0, #2_00100000
	beq Escreve_Led
	cmp r10, #13
	itt eq
	moveq r0, #2_01000000
	beq Escreve_Led
	b . 
Escreve_Led
	and r3, r0, #2_00001111
	and r4, r0, #2_11110000
	b Escreve_Multiplexado
Escreve_Digito
	bl Num_to_7Seg
	and r3, r0, #2_00001111
	and r4, r0, #2_11110000
	b Escreve_Multiplexado
Escreve_Multiplexado
	LDR	R1, =GPIO_PORTQ_AHB_DATA_R		    
	LDR R2, [R1]
	BIC R2, #2_00001111                     
	ORR R3, R3, R2                          
	STR R3, [R1]

	LDR	R1, =GPIO_PORTA_AHB_DATA_R		    
	LDR R2, [R1]
	BIC R2, #2_11110000                   
	ORR R4, R4, R2                         
	STR R4, [R1]  
	
	b Espera10ms

Espera10ms
	mov r0, #10
	bl SysTick_Wait1ms
	
Logica_Displays
	add r6, #1
	cmp r6, #100
	bne Logica_Leds
	b Muda_Unidade
Muda_Unidade
	mov r6, #0
	add r8, r5
	cmp r8, #10
	beq Aumenta_Dezena
	cmp r8, #-1
	bne Logica_Leds
Diminui_Dezena
	mov r8, #9
	add r9, #-1
	cmp r9, #-1
	bne Logica_Leds
Loop_Negativo_Dezena
	mov r9, #9
	b Logica_Leds
Aumenta_Dezena
	mov r8, #0
	add r9, #1
	cmp r9, #10
	bne Logica_Leds
Loop_Positivo_Dezena
	mov r9, #0
	bne Logica_Leds
	
Logica_Leds
	cmp r6, #0
	beq Anda_Led
	cmp r11, #1
	bne Checa_Botoes
	cmp r6, #50
	bne Checa_Botoes
	b Anda_Led
Anda_Led
	add r10, #1
	cmp r10, #14
	bne Checa_Botoes
Loop_Leds
	mov r10, #0
	b Checa_Botoes

Checa_Botoes
	BL PortJ_Input				 ;Chama a subrotina que lê o estado das chaves e coloca o resultado em R0
	cmp r12, #1
	and r1, r0, #2_01
	and r2, r0, #2_10
	beq Checa_Ambos
Checa_SW1	
	CMP R1, #0			 
	bne Checa_SW2
	mov r3, #0
	sub r5, r3, r5
	b Checa_SW2
Checa_SW2	
	cmp r2, #0	
	bne Checa_Ambos
	eor r11, #1
	b Checa_Ambos

Checa_Ambos
	cmp r1, #0
	beq Algum_Botao_Apertado
	cmp r2, #0
	beq Algum_Botao_Apertado
	mov r12, #0
	B MainLoop                   ;Volta para o laço principal	
Algum_Botao_Apertado
	mov r12, #1
	B MainLoop

    ALIGN                        ;Garante que o fim da seção está alinhada 
    END                          ;Fim do arquivo
