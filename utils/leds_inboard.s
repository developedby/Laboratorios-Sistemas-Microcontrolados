; gpio.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 19/03/2018

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declarações EQU - Defines
; ========================
; Definições de Valores
BIT0	EQU 2_0001
BIT1	EQU 2_0010
; ========================
; Definições dos Registradores Gerais
SYSCTL_RCGCGPIO_R	 EQU	0x400FE608
SYSCTL_PRGPIO_R		 EQU    0x400FEA08
; ========================
; Definições dos Ports


; PORT N
GPIO_PORTN_AHB_LOCK_R    	EQU    0x40064520
GPIO_PORTN_AHB_CR_R      	EQU    0x40064524
GPIO_PORTN_AHB_AMSEL_R   	EQU    0x40064528
GPIO_PORTN_AHB_PCTL_R    	EQU    0x4006452C
GPIO_PORTN_AHB_DIR_R     	EQU    0x40064400
GPIO_PORTN_AHB_AFSEL_R   	EQU    0x40064420
GPIO_PORTN_AHB_DEN_R     	EQU    0x4006451C
GPIO_PORTN_AHB_PUR_R     	EQU    0x40064510	
GPIO_PORTN_AHB_DATA_R    	EQU    0x400643FC
GPIO_PORTN               	EQU    2_001000000000000	

; PORT F
GPIO_PORTF_AHB_LOCK_R    	EQU    0x4005d520
GPIO_PORTF_AHB_CR_R      	EQU    0x4005d524
GPIO_PORTF_AHB_AMSEL_R   	EQU    0x4005d528
GPIO_PORTF_AHB_PCTL_R    	EQU    0x4005d52C
GPIO_PORTF_AHB_DIR_R     	EQU    0x4005d400
GPIO_PORTF_AHB_AFSEL_R   	EQU    0x4005d420
GPIO_PORTF_AHB_DEN_R     	EQU    0x4005d51C
GPIO_PORTF_AHB_PUR_R     	EQU    0x4005d510	
GPIO_PORTF_AHB_DATA_R    	EQU    0x4005d3FC
GPIO_PORTF               	EQU    2_000000000100000	

; -------------------------------------------------------------------------------
; Área de Código - Tudo abaixo da diretiva a seguir será armazenado na memória de 
;                  código
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma função do arquivo for chamada em outro arquivo	
		export Init_Leds
		export Acende_Led
		export Apaga_Led

;--------------------------------------------------------------------------------
; Função Init_Leds
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
Init_Leds
;=====================
; 1. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO,
; após isso verificar no PRGPIO se a porta está pronta para uso.
; enable clock to GPIOF at clock gating register
	LDR		R0, =SYSCTL_RCGCGPIO_R
	ldr		r1, [r0]
	orr		r1, #GPIO_PORTF	
	orr 	r1, #GPIO_PORTN
	str r1, [r0]

	LDR     R0, =SYSCTL_PRGPIO_R			;Carrega o endereço do PRGPIO para esperar os GPIO ficarem prontos
EsperaGPIO
	LDR     R1, [R0]						;Lê da memória o conteúdo do endereço do registrador
	mov 	r2, r1
	orr		R2, #GPIO_PORTF                 ;Seta o bit da porta A
	ORR     R2, #GPIO_PORTN					;Seta o bit da porta B, fazendo com OR
	TST     R1, R2							;ANDS de R1 com R2
	BEQ     EsperaGPIO					    ;Se o flag Z=1, volta para o laço. Senão continua executando
	
; 2. Limpar o AMSEL para desabilitar a analógica
	MOV     R1, #0x00						;Colocar 0 no registrador para desabilitar a função analógica
    LDR     R0, =GPIO_PORTF_AHB_AMSEL_R     ;Carrega o R0 com o endereço do AMSEL para a porta J
    STR     R1, [R0]	
	;Colocar 0 no registrador para desabilitar a função analógica
    LDR     R0, =GPIO_PORTN_AHB_AMSEL_R     ;Carrega o R0 com o endereço do AMSEL para a porta J
    STR     R1, [R0]					    ;Colocar 0 no registrador para selecionar o modo GPIO
	
; 3. Limpar PCTL para selecionar o GPIO
	MOV     R1, #0x00
    LDR     R0, =GPIO_PORTF_AHB_PCTL_R		;Carrega o R0 com o endereço do PCTL para a porta J
    STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTN_AHB_PCTL_R		;Carrega o R0 com o endereço do PCTL para a porta J
    STR     R1, [R0]
	
; 4. DIR para 0 se for entrada, 1 se for saída	
	LDR     R0, =GPIO_PORTN_AHB_DIR_R		;Carrega o R0 com o endereço do DIR para a porta N
	ldr		r1, [r0]
	orr     R1, #2_00000011    				;Enviar o valor 0x03 para habilitar os pinos como saída
    STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTF_AHB_DIR_R		;Carrega o R0 com o endereço do DIR para a porta N
	ldr		r1, [r0]
	orr     R1, #2_00010001     			;Enviar o valor 0x03 para habilitar os pinos como saída
    STR     R1, [R0]
	
; 5. Limpar os bits AFSEL para 0 para selecionar GPIO sem função alternativa
	MOV     R1, #0x00						;Colocar o valor 0 para não setar função alternativa
	LDR     R0, =GPIO_PORTN_AHB_AFSEL_R		;Carrega o endereço do AFSEL da porta N
	STR     R1, [R0]
	LDR     R0, =GPIO_PORTF_AHB_AFSEL_R		;Carrega o endereço do AFSEL da porta N
	STR     R1, [R0]

; 6. Setar os bits de DEN para habilitar I/O digital
	LDR     R0, =GPIO_PORTN_AHB_DEN_R			;Carrega o endereço do DEN
	LDR     R1, [R0]							;Ler da memória o registrador GPIO_PORTN_AHB_DEN_R
	orr     r1, #2_00000011						;Habilitar funcionalidade digital na DEN os bits 0 e 1
	STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTF_AHB_DEN_R			;Carrega o endereço do DEN
	LDR     R1, [R0]							;Ler da memória o registrador GPIO_PORTN_AHB_DEN_R
	orr     R1, #2_00010001						;Habilitar funcionalidade digital na DEN os bits 0 e 1
	STR     R1, [R0]
	
; 7. Para habilitar resistor de pull-up interno, setar PUR para 1
	;LDR     R0, =GPIO_PORTJ_AHB_PUR_R			;Carrega o endereço do PUR para a porta J
	;MOV     R1, #BIT0							;Habilitar funcionalidade digital de resistor de pull-up 
	;ORR     R1, #BIT1							;nos bits 0 e 1
	;STR     R1, [R0]							;Escreve no registrador da memória do resistor de pull-up
	
	bx lr

; Entrada numero do led (0,1,2,3) - R0
Acende_Led
	push {r1-r4}
	LDR	R1, =GPIO_PORTN_AHB_DATA_R		    
	LDR R2, [R1]
	LDR	R3, =GPIO_PORTF_AHB_DATA_R		    
	LDR R4, [R3]
                   
	cmp r0, #0
	bne Nao_E_Led_0
	orr r2, #2_00000010
	str r2, [r1]
	pop {r1-r4}
	bx lr
Nao_E_Led_0
	cmp r0, #1
	bne Nao_E_Led_1
	orr r2, #2_00000001
	str r2, [r1]
	pop {r1-r4}
	bx lr
Nao_E_Led_1
	cmp r0, #2
	bne Nao_E_Led_2
	orr r4, #2_00010000
	str r4, [r3]
	pop {r1-r4}
	bx lr
Nao_E_Led_2
	cmp r0, #3
	bne Nao_E_Led_Nenhum
	orr r4, #2_00000001
	str r4, [r3]
	pop {r1-r4}
	bx lr
Nao_E_Led_Nenhum
	pop {r1-r4}
	bx lr
	
; Entrada numero do led (0,1,2,3) - R0
Apaga_Led
	push {r1-r4}
	LDR	R1, =GPIO_PORTN_AHB_DATA_R		    
	LDR R2, [R1]
	LDR	R3, =GPIO_PORTF_AHB_DATA_R		    
	LDR R4, [R3]
                   
	cmp r0, #0
	bne Nao_E_Led_0_Apaga
	bic r2, #2_00000010
	str r2, [r1]
	pop {r1-r4}
	bx lr
Nao_E_Led_0_Apaga
	cmp r0, #1
	bne Nao_E_Led_1_Apaga
	bic r2, #2_00000001
	str r2, [r1]
	pop {r1-r4}
	bx lr
Nao_E_Led_1_Apaga
	cmp r0, #2
	bne Nao_E_Led_2_Apaga
	bic r4, #2_00010000
	str r4, [r3]
	pop {r1-r4}
	bx lr
Nao_E_Led_2_Apaga
	cmp r0, #3
	bne Nao_E_Led_Nenhum_Apaga
	bic r4, #2_00000001
	str r4, [r3]
	pop {r1-r4}
	bx lr
Nao_E_Led_Nenhum_Apaga
	pop {r1-r4}
	bx lr

    ALIGN                           ; garante que o fim da seção está alinhada 
    END                             ; fim do arquivo