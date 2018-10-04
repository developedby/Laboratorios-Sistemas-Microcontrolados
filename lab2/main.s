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
		IMPORT	PLL_Init
		IMPORT	SysTick_Init
		IMPORT	SysTick_Wait1ms
			
		IMPORT	PortJ_Input
			
		IMPORT Init_Display
		IMPORT Display_Send_Data
		IMPORT Display_Send_Instruction
; -------------------------------------------------------------------------------


; Função main()
Start  			
	BL PLL_Init                  ;Chama a subrotina para alterar o clock do microcontrolador para 80MHz
	BL SysTick_Init              ;Chama a subrotina para inicializar o SysTick
	BL GPIO_Init                 ;Chama a subrotina que inicializa os GPIO
	bl Init_Display

Checa_Botoes
	BL PortJ_Input				 ;Chama a subrotina que lê o estado das chaves e coloca o resultado em R0
	
	mov r1, r0
	and r1, #1

	mov r2, r0
	and r2, #2

Checa_Ambos
	cmp r1, #0
	beq Algum_Botao_Apertado
	cmp r2, #0
	beq Algum_Botao_Apertado

	B Checa_Botoes                   ;Volta para o laço principal	


Algum_Botao_Apertado
	mov r4, #'B'
	bl Display_Send_Data
	mov r4, #'A'
	bl Display_Send_Data
	mov r4, #'T'
	bl Display_Send_Data
	mov r4, #'A'
	bl Display_Send_Data
	mov r4, #'T'
	bl Display_Send_Data
	mov r4, #'A'
	bl Display_Send_Data

	b .




    ALIGN                        ;Garante que o fim da seção está alinhada 
    END                          ;Fim do arquivo
