; Biblioteca em assembly para uso de teclado matricial 3x4 com a PAT DAELN e Tiva C TM4C129
; Nicolas Abril e Lucca Rawlyk


; Definições de constantes de GPIO

; Definições dos Registradores Gerais
SYSCTL_RCGCGPIO_R	 EQU	0x400FE608
SYSCTL_PRGPIO_R		 EQU    0x400FEA08
	
GPIO_PORTL_AHB_LOCK_R    	EQU    0x40062520
GPIO_PORTL_AHB_CR_R      	EQU    0x40062524
GPIO_PORTL_AHB_AMSEL_R   	EQU    0x40062528
GPIO_PORTL_AHB_PCTL_R    	EQU    0x4006252C
GPIO_PORTL_AHB_DIR_R     	EQU    0x40062400
GPIO_PORTL_AHB_AFSEL_R   	EQU    0x40062420
GPIO_PORTL_AHB_DEN_R     	EQU    0x4006251C
GPIO_PORTL_AHB_PUR_R     	EQU    0x40062510	
GPIO_PORTL_AHB_DATA_R    	EQU    0x400623FC
GPIO_PORTL               	EQU    2_000010000000000	
	
GPIO_PORTC_AHB_LOCK_R    	EQU    0x4005A520
GPIO_PORTC_AHB_CR_R      	EQU    0x4005A524
GPIO_PORTC_AHB_AMSEL_R   	EQU    0x4005A528
GPIO_PORTC_AHB_PCTL_R    	EQU    0x4005A52C
GPIO_PORTC_AHB_DIR_R     	EQU    0x4005A400
GPIO_PORTC_AHB_AFSEL_R   	EQU    0x4005A420
GPIO_PORTC_AHB_DEN_R     	EQU    0x4005A51C
GPIO_PORTC_AHB_PUR_R     	EQU    0x4005A510	
GPIO_PORTC_AHB_DATA_R    	EQU    0x4005A3FC
GPIO_PORTC               	EQU    2_000000000000100	

		AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
		export Init_Teclado



Init_Teclado
; 1. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO,
; após isso verificar no PRGPIO se a porta está pronta para uso.
; enable clock to GPIOF at clock gating register
	push {r0-r2}
	LDR		R0, =SYSCTL_RCGCGPIO_R
	ldr		r1, [r0]
	orr		r1, #GPIO_PORTL	
	orr 	r1, #GPIO_PORTC
	str 	r1, [r0]

	LDR     R0, =SYSCTL_PRGPIO_R			;Carrega o endereço do PRGPIO para esperar os GPIO ficarem prontos
EsperaGPIO
	LDR     R1, [R0]						;Lê da memória o conteúdo do endereço do registrador
	mov 	r2, r1
	orr		R2, #GPIO_PORTL                 ;Seta o bit da porta A
	ORR     R2, #GPIO_PORTC					;Seta o bit da porta B, fazendo com OR
	TST     R1, R2							;ANDS de R1 com R2
	BEQ     EsperaGPIO					    ;Se o flag Z=1, volta para o laço. Senão continua executando
	
; 2. Limpar o AMSEL para desabilitar a analógica
    LDR     R0, =GPIO_PORTL_AHB_AMSEL_R     ;Carrega o R0 com o endereço do AMSEL para a porta J
	LDR		r1, [r0]
	bic 	r1, #0x0F
    STR     R1, [R0]	
	;Colocar 0 no registrador para desabilitar a função analógica
    LDR     R0, =GPIO_PORTC_AHB_AMSEL_R     ;Carrega o R0 com o endereço do AMSEL para a porta J
	ldr		r1, [r0]
	bic		r1, #0xf0
    STR     R1, [R0]					    ;Colocar 0 no registrador para selecionar o modo GPIO
	
; 3. Limpar PCTL para selecionar o GPIO
    LDR     R0, =GPIO_PORTL_AHB_PCTL_R		;Carrega o R0 com o endereço do PCTL para a porta J
    LDR		r1, [r0]
	bic 	r1, #0x0F
    STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTC_AHB_PCTL_R		;Carrega o R0 com o endereço do PCTL para a porta J
    ldr		r1, [r0]
	bic		r1, #0xf0
    STR     R1, [R0]
	
; 4. DIR para 0 se for entrada, 1 se for saída	
	LDR     R0, =GPIO_PORTC_AHB_DIR_R		;Carrega o R0 com o endereço do DIR para a porta N
	ldr		r1, [r0]
	bic     R1, #0xf0    		 			;Entrada do teclado (4 colunas)
    STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTL_AHB_DIR_R		;Carrega o R0 com o endereço do DIR para a porta N
	ldr		r1, [r0]
	orr     R1, #0x0f     					;Saida do teclado (3 linhas e pull-up)
    STR     R1, [R0]
	
; 5. Limpar os bits AFSEL para 0 para selecionar GPIO sem função alternativa
	LDR     R0, =GPIO_PORTC_AHB_AFSEL_R		;Carrega o endereço do AFSEL da porta N
	ldr		r1, [r0]
	bic		r1, #0xf0
	STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTL_AHB_AFSEL_R		;Carrega o endereço do AFSEL da porta N
	ldr		r1, [r0]
	bic 	r1, #0x0f
	STR     R1, [R0]

; 6. Setar os bits de DEN para habilitar I/O digital
	LDR     R0, =GPIO_PORTC_AHB_DEN_R			;Carrega o endereço do DEN
	LDR     R1, [R0]							;Ler da memória o registrador GPIO_PORTN_AHB_DEN_R
	orr     r1, #0xf0							;Habilitar funcionalidade digital na DEN os bits 0 e 1
	STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTL_AHB_DEN_R			;Carrega o endereço do DEN
	LDR     R1, [R0]							;Ler da memória o registrador GPIO_PORTN_AHB_DEN_R
	orr     R1, #0x0f						;Habilitar funcionalidade digital na DEN os bits 0 e 1
	STR     R1, [R0]
	
	; Liga o VCC do teclado e desliga as linhas
	ldr r0, =GPIO_PORTL_AHB_DATA_R
	ldr r1, [r0]
	bic r1, #2_0111
	orr r1, #2_1000
	str r1, [r0]
	
	pop {r0-r2}
	bx lr
	
; Retorna em r0 a tecla pressionada (prioridade para a ordem de varredura)
Varre_Teclado
	push {}	
	ldr r0, =GPIO_PORTL_AHB_DATA_R
	ldr r2, =GPIO_PORTC_AHB_DATA_R
	
	ldr r1, [r0]
	bic	r1, #2_0110
	orr r1, #2_1001
	str r1, [r0]

	ldr r3, [r2]
	mov r4, r3
	and r4, #2_1000000

	ALIGN
	END