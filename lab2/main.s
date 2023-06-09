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
ESTADO_TABUADA	SPACE	40
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
		IMPORT	PLL_Init
		IMPORT	SysTick_Init
		IMPORT	SysTick_Wait1ms
			
			
		IMPORT Init_Display
		IMPORT Display_Send_Data
		IMPORT Display_Send_Instruction

		import Init_Teclado
		import Varre_Teclado
		import Mapeia_Tecla
		
		import Init_Leds
		import Acende_Led
		import Apaga_Led

; -------------------------------------------------------------------------------


; Fun��o main()
Start  			
	BL PLL_Init                  ;Chama a subrotina para alterar o clock do microcontrolador para 80MHz
	BL SysTick_Init              ;Chama a subrotina para inicializar o SysTick
	bl Init_Display
	bl Init_Teclado
	bl Init_Leds

	ldr r7, =ESTADO_TABUADA
	mov r0, #0
	str r0, [r7]
	str r0, [r7,#4]
	str r0, [r7,#8]
	str r0, [r7,#12]
	str r0, [r7,#16]
	str r0, [r7,#20]
	str r0, [r7,#24]
	str r0, [r7,#28]
	str r0, [r7,#32]
	str r0, [r7,#36]

Initial_Loop
	mov r5, #-1					; R5 contem o numero da tabuada (ultima tecla)
	mov r6, #0					; R6 contem o contador da tabuada

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
	mov r0, #300				;Debounce 1s
	bl SysTick_Wait1ms
	bl Varre_Teclado
	bl Mapeia_Tecla
	cmp r0, #-1
	beq Main_Loop

Tecla_Pressionada
	cmp r0, #'9'
	bgt Tecla_Invalida_Pressionada
	cmp r0, #'0'
	blt	Tecla_Invalida_Pressionada
	b Tecla_Valida_Pressionada

Tecla_Invalida_Pressionada
	cmp r5, #-1
	beq Initial_Loop	; Se tava em nenhuma tabuada nao salva
	mov r2, #4
	; Guarda tabuada antiga
	mul r1, r5, r2
	str r6, [r7,r1]
	b Initial_Loop

Tecla_Valida_Pressionada
	sub r0, #'0'
	cmp r0, r5					; Ve se a tecla pressionada e igual a ultima
	beq Incrementa_Tabuada
	bne Nova_Tabuada
Nova_Tabuada
	cmp r5, #-1
	mov r2, #4
	beq Carrega_Nova_Tabuada	; Se tava em nenhuma tabuada nao salva
	; Guarda tabuada antiga
	mul r1, r5, r2
	str r6, [r7,r1]
Carrega_Nova_Tabuada
	mov r5, r0
	mul r1, r5, r2
	ldr r6, [r7,r1]
	b Exibe_Tabuada

Incrementa_Tabuada
	add r6, #1					; incrementa
	cmp r6, #10					; se passou do maximo volta
	it eq
	moveq r6, #0
	b Exibe_Tabuada

Exibe_Tabuada
	mov r4, #0x01				; Vai com cursor para home
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
	add r4, #'0'
	bl Display_Send_Data
Modulo_10
	cmp r3, #10
	itt ge 
	subge r3, #10
	bge Modulo_10
	mov r4, r3
	add r4, #'0'
	bl Display_Send_Data

	; Se contador = 9, acende led por 2s
	cmp r6, #9
	bne Main_Loop

	mov r0, #0
	bl Acende_Led
	mov r0, #2000
	bl SysTick_Wait1ms
	mov r0, #0
	bl Apaga_Led

	b Main_Loop

    ALIGN                        ;Garante que o fim da se��o est� alinhada 
    END                          ;Fim do arquivo
