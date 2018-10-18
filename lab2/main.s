; main.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 15/03/2018
; Este programa espera o usu�rio apertar a chave USR_SW1 e/ou a chave USR_SW2.
; Caso o usu�rio pressione a chave USR_SW1, acender� o LED2. Caso o usu�rio pressione 
; a chave USR_SW2, acender� o LED1. Caso as duas chaves sejam pressionadas, os dois 
; LEDs acendem.

; -------------------------------------------------------------------------------
        THUMB                        ; Instru��es do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declara��es EQU - Defines
;<NOME>         EQU <VALOR>
; ========================
; Defini��es de Valores
BIT0	EQU 2_0001
BIT1	EQU 2_0010
	

; -------------------------------------------------------------------------------
; �rea de Dados - Declara��es de vari�veis
		AREA  DATA, ALIGN=2
		; Se alguma vari�vel for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a vari�vel <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma vari�vel de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posi��o da RAM		

; -------------------------------------------------------------------------------
; �rea de C�digo - Tudo abaixo da diretiva a seguir ser� armazenado na mem�ria de 
;                  c�digo
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma fun��o do arquivo for chamada em outro arquivo	
        EXPORT Start                ; Permite chamar a fun��o Start a partir de 
			                        ; outro arquivo. No caso startup.s
									
		; Se chamar alguma fun��o externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma 
									; fun��o <func>
		IMPORT  GPIO_Init
		IMPORT	PLL_Init
		IMPORT	SysTick_Init
		IMPORT	SysTick_Wait1ms
			
		IMPORT	PortJ_Input
			
		IMPORT Init_Display
		IMPORT Display_Send_Data
		IMPORT Display_Send_Instruction

		import Init_Teclado
		import Varre_Teclado

; -------------------------------------------------------------------------------


; Fun��o main()
Start  			
	BL PLL_Init                  ;Chama a subrotina para alterar o clock do microcontrolador para 80MHz
	BL SysTick_Init              ;Chama a subrotina para inicializar o SysTick
	BL GPIO_Init                 ;Chama a subrotina que inicializa os GPIO
	bl Init_Display
	bl Init_Teclado

Inicia_Variaveis
	mov r5, #0					; R5 contem o numero da tabuada (ultima tecla)
	mov r6, #0					; R6 contem o contador da tabuada


Initial_Loop
	mov r4, #0x01				; Limpa display
	bl Display_Send_Instruction
	mov r4, #'A'
	bl Display_Send_Data
	mov r4, #'P'
	bl Display_Send_Data
	mov r4, #'E'
	bl Display_Send_Data
	mov r4, #'R'
	bl Display_Send_Data
	mov r4, #'T'
	bl Display_Send_Data
	mov r4, #'E'
	bl Display_Send_Data
	mov r4, #' '
	bl Display_Send_Data
	mov r4, #'U'
	bl Display_Send_Data
	mov r4, #'M'
	bl Display_Send_Data
	mov r4, #' '
	bl Display_Send_Data
	mov r4, #'N'
	bl Display_Send_Data
	mov r4, #'U'
	bl Display_Send_Data
	mov r4, #'M'
	bl Display_Send_Data
	mov r4, #'E'
	bl Display_Send_Data
	mov r4, #'R'
	bl Display_Send_Data
	mov r4, #'O'
	bl Display_Send_Data

Main_Loop
	mov r0, #1000				;Debounce 1s
	bl SysTick_Wait1ms

	bl Varre_Teclado
	cmp r0, #0
	beq Main_Loop

Tecla_Pressionada
	cmp r0, #9 					; So queremos as primeiras 9
	bgt Initial_Loop

	cmp r0, r5					; Ve se a tecal pressionada e igual a ultima
	beq Incrementa_Tabuada
	bne Nova_Tabuada
Nova_Tabuada
	mov r5, r0
	mov r6, #0
	b Exibe_Tabuada

Incrementa_Tabuada
	add r6, #1					; inceremnta
	cmp r6, #10					; se passou do maximo volta
	it eq
	moveq r6, #0
	b Exibe_Tabuada

Exibe_Tabuada
	mov r4, #0x02				; Vai com cursor para home
	bl Display_Send_Instruction
	mov r4, #'T'
	bl Display_Send_Data
	mov r4, #'A'
	bl Display_Send_Data
	mov r4, #'B'
	bl Display_Send_Data
	mov r4, #'U'
	bl Display_Send_Data
	mov r4, #'A'
	bl Display_Send_Data
	mov r4, #'D'
	bl Display_Send_Data
	mov r4, #'A'
	bl Display_Send_Data
	mov r4, #' '
	bl Display_Send_Data
	mov r4, #'D'
	bl Display_Send_Data
	mov r4, #'O'
	bl Display_Send_Data
	mov r4, #' '
	bl Display_Send_Data
	add r4, r5, #'0'
	bl Display_Send_Data
	
	mov r4, #0xc0				; Vai com cursor para 2a linha
	bl Display_Send_Instruction

	add r4, r5, #'0'
	bl Display_Send_Data
	mov r4, #'x'
	bl Display_Send_Data
	add r4, R6, #'0'
	bl Display_Send_Data
	mov r4, #' '
	bl Display_Send_Data
	mov r4, #'='
	bl Display_Send_Data
	mov r4, #' '
	bl Display_Send_Data
	mul r3, r5, r6
	mov r2, #10
	sdiv r4, r3, r2
	bl Display_Send_Data
Modulo_10
	cmp r3, #10
	itt gt 
	subgt r3, #10
	bgt Modulo_10
	mov r4, r3
	bl Display_Send_Data

	; Se contador = 9, acende led por 2s
	cmp r6, #9
	bne Main_Loop

	;TODO:LIGAR AQUI O LED
	mov r0, #2000
	bl SysTick_Wait1ms
	;TODO:DESLIGAR AQUIO O LED

	b Main_Loop

    ALIGN                        ;Garante que o fim da se��o est� alinhada 
    END                          ;Fim do arquivo
