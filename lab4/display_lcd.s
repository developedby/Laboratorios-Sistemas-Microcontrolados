; Biblioteca em assembly para uso de Display LCD com a placa PAT DAELN e Tiva C TM4C129

; Definições de constantes de GPIO

; Definições dos Registradores Gerais
SYSCTL_RCGCGPIO_R	 EQU	0x400FE608
SYSCTL_PRGPIO_R		 EQU    0x400FEA08

GPIO_PORTM_AHB_LOCK_R    	EQU    0x40063520
GPIO_PORTM_AHB_CR_R      	EQU    0x40063524
GPIO_PORTM_AHB_AMSEL_R   	EQU    0x40063528
GPIO_PORTM_AHB_PCTL_R    	EQU    0x4006352C
GPIO_PORTM_AHB_DIR_R     	EQU    0x40063400
GPIO_PORTM_AHB_AFSEL_R   	EQU    0x40063420
GPIO_PORTM_AHB_DEN_R     	EQU    0x4006351C
GPIO_PORTM_AHB_PUR_R     	EQU    0x40063510	
GPIO_PORTM_AHB_DATA_R    	EQU    0x400633FC
GPIO_PORTM               	EQU    2_000100000000000	
	
GPIO_PORTK_AHB_LOCK_R    	EQU    0x40061520
GPIO_PORTK_AHB_CR_R      	EQU    0x40061524
GPIO_PORTK_AHB_AMSEL_R   	EQU    0x40061528
GPIO_PORTK_AHB_PCTL_R    	EQU    0x4006152C
GPIO_PORTK_AHB_DIR_R     	EQU    0x40061400
GPIO_PORTK_AHB_AFSEL_R   	EQU    0x40061420
GPIO_PORTK_AHB_DEN_R     	EQU    0x4006151C
GPIO_PORTK_AHB_PUR_R     	EQU    0x40061510	
GPIO_PORTK_AHB_DATA_R    	EQU    0x400613FC
GPIO_PORTK               	EQU    2_000001000000000	


		AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        
	IMPORT	SysTick_Init
	IMPORT	SysTick_Wait1ms

; Subrotinas a exportar
	export Init_Display
	export Display_Send_Data
	export Display_Send_Instruction

; Inicializa o display, configurando a GPIO para a PAT DAELN
Init_Display
	push {r0-r5}
	
Init_Display_Ports
; 1. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO,
; após isso verificar no PRGPIO se a porta está pronta para uso.
; enable clock to GPIOF at clock gating register
	LDR		R0, =SYSCTL_RCGCGPIO_R
	ldr		r1, [r0]
	orr		r1, #GPIO_PORTM	
	orr 	r1, #GPIO_PORTK
	str r1, [r0]

	LDR     R0, =SYSCTL_PRGPIO_R			;Carrega o endereço do PRGPIO para esperar os GPIO ficarem prontos
EsperaGPIO
	LDR     R1, [R0]						;Lê da memória o conteúdo do endereço do registrador
	mov 	r2, r1
	orr		R2, #GPIO_PORTM                 ;Seta o bit da porta A
	ORR     R2, #GPIO_PORTK					;Seta o bit da porta B, fazendo com OR
	TST     R1, R2							;ANDS de R1 com R2
	BEQ     EsperaGPIO					    ;Se o flag Z=1, volta para o laço. Senão continua executando
	
; 2. Limpar o AMSEL para desabilitar a analógica
	MOV     R1, #0x00						;Colocar 0 no registrador para desabilitar a função analógica
    LDR     R0, =GPIO_PORTM_AHB_AMSEL_R     ;Carrega o R0 com o endereço do AMSEL para a porta J
    STR     R1, [R0]	
	;Colocar 0 no registrador para desabilitar a função analógica
    LDR     R0, =GPIO_PORTK_AHB_AMSEL_R     ;Carrega o R0 com o endereço do AMSEL para a porta J
    STR     R1, [R0]					    ;Colocar 0 no registrador para selecionar o modo GPIO
	
; 3. Limpar PCTL para selecionar o GPIO
	MOV     R1, #0x00
    LDR     R0, =GPIO_PORTM_AHB_PCTL_R		;Carrega o R0 com o endereço do PCTL para a porta J
    STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTK_AHB_PCTL_R		;Carrega o R0 com o endereço do PCTL para a porta J
    STR     R1, [R0]
	
; 4. DIR para 0 se for entrada, 1 se for saída	
	LDR     R0, =GPIO_PORTK_AHB_DIR_R		;Carrega o R0 com o endereço do DIR para a porta N
	ldr		r1, [r0]
	orr     R1, #2_11111111     			;Enviar o valor 0x03 para habilitar os pinos como saída
    STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTM_AHB_DIR_R		;Carrega o R0 com o endereço do DIR para a porta N
	ldr		r1, [r0]
	orr     R1, #0000000111     			;Enviar o valor 0x03 para habilitar os pinos como saída
    STR     R1, [R0]
	
; 5. Limpar os bits AFSEL para 0 para selecionar GPIO sem função alternativa
	MOV     R1, #0x00						;Colocar o valor 0 para não setar função alternativa
	LDR     R0, =GPIO_PORTK_AHB_AFSEL_R		;Carrega o endereço do AFSEL da porta N
	STR     R1, [R0]
	LDR     R0, =GPIO_PORTM_AHB_AFSEL_R		;Carrega o endereço do AFSEL da porta N
	STR     R1, [R0]

; 6. Setar os bits de DEN para habilitar I/O digital
	LDR     R0, =GPIO_PORTK_AHB_DEN_R			;Carrega o endereço do DEN
	LDR     R1, [R0]							;Ler da memória o registrador GPIO_PORTN_AHB_DEN_R
	orr     r1, #2_11111111						;Habilitar funcionalidade digital na DEN os bits 0 e 1
	STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTM_AHB_DEN_R			;Carrega o endereço do DEN
	LDR     R1, [R0]							;Ler da memória o registrador GPIO_PORTN_AHB_DEN_R
	orr     R1, #2_00000111						;Habilitar funcionalidade digital na DEN os bits 0 e 1
	STR     R1, [R0]
	
; 7. Para habilitar resistor de pull-up interno, setar PUR para 1
	;LDR     R0, =GPIO_PORTJ_AHB_PUR_R			;Carrega o endereço do PUR para a porta J
	;MOV     R1, #BIT0							;Habilitar funcionalidade digital de resistor de pull-up 
	;ORR     R1, #BIT1							;nos bits 0 e 1
	;STR     R1, [R0]							;Escreve no registrador da memória do resistor de pull-up
	
Init_Display_Config	
	; Inicializar no modo 2 linhas / caracter matriz 5x7
	mov r4, #0x38
	push {lr}
	bl Display_Send_Instruction
	pop {lr}

	; Cursor com autoincremento para direita
	mov r4, #0x06
	push {lr}
	bl Display_Send_Instruction
	pop {lr}
	
	; Configurar o cursor (habilitar o display + cursor + pisca) 
	mov r4, #0x0E
	push {lr}
	bl Display_Send_Instruction
	pop {lr}
	
	; Configurar o cursor piscante 
	mov r4, #0x0F
	push {lr}
	bl Display_Send_Instruction
	pop {lr}
	
	; Limpar o display e levar o cursor para o home
	mov r4, #0x01
	push {lr}
	bl Display_Send_Instruction
	pop {lr}

	pop {r0-r5}
	bx lr
	
	
; Espera o display estar pronto (le a busy flag)	
Wait_For_Display
	
	push {r0-r3}
	
	; Seta os dados do display como entrada
	LDR     R0, =GPIO_PORTK_AHB_DIR_R			;Carrega o endereço do DIR
	LDR     R1, [R0]							;Ler da memória o registrador GPIO_PORTK_AHB_DIR_R
	push 	{r1}
	bic     r1, #2_11111111						; Le o display
	STR     R1, [R0]
	
	ldr r0, =GPIO_PORTM_AHB_DATA_R
	ldr r1, =GPIO_PORTK_AHB_DATA_R
	ldr r2, [r0]
	
	; RS=0, RW=1, EN=1 (le estado)
	bic r2, #2_00000001
	orr r2, #2_00000110	
	str r2, [r0]
	
	push {r0, r1, r3, lr}
	mov r0, #1
	bl SysTick_Wait1ms
	pop {r0, r1, r3, lr}
	b Fim
	
	; EN=0 (da clock no display)
	bic r2, #2_00000100
	str r2, [r0]
	
Display_Not_Ready_Loop
	ldr r3, [r1]
	and r3, #2_10000000
	cmp r3, #2_10000000
	beq Display_Not_Ready_Loop
	
Fim
	; Restaura GPIO_PORTK_AHB_DIR_R
	LDR     R0, =GPIO_PORTK_AHB_DIR_R			
	pop 	{r1}						
	STR     R1, [R0]

	pop {r0-r3}
	bx lr
	
; Envia comando para o display
; Entrada em r0
Display_Send_Instruction
	push {r0-r4}

	; Seta os dados do display como saida
	LDR     R4, =GPIO_PORTK_AHB_DIR_R			;Carrega o endereço do DEN
	LDR     R1, [R4]							;Ler da memória o registrador GPIO_PORTN_AHB_DEN_R
	push 	{r1}
	orr     r1, #2_11111111						;Habilitar funcionalidade digital na DEN os bits 0 e 1
	STR     R1, [R4]

	ldr r4, =GPIO_PORTM_AHB_DATA_R
	ldr r1, =GPIO_PORTK_AHB_DATA_R
	
	ldr r2, [r4]
	ldr r3, [r1]

	and r0, #2_11111111

	; RS=0, RW=0, EN=1 (envia comando)
	bic r2, #2_00000011
	orr r2, #2_00000100	
	str r2, [r4]
	
	; Escreve o comando na porta de dados do display
	orr r3, r0
	eor r0, #2_11111111
	bic r3, r0
	str r3, [r1]
	
	push {r0, r1, r3, lr}
	mov r0, #1
	bl SysTick_Wait1ms
	pop {r0, r1, r3, lr}
	
	; EN=0 (da clock no display)
	bic r2, #2_00000100
	str r2, [r4]
	
	LDR R4, =GPIO_PORTK_AHB_DIR_R
	pop {r1}
	str r1, [r4]
	
	push {lr}
	bl Wait_For_Display
	pop {lr}
	
	pop {r0-r4}
	bx lr

; Envia dados para o display
; Entrada em r0
Display_Send_Data
	push {r0-r4}

	; Seta os dados do display como saida
	LDR     R4, =GPIO_PORTK_AHB_DIR_R			;Carrega o endereço do DEN
	LDR     R1, [R4]							;Ler da memória o registrador GPIO_PORTN_AHB_DEN_R
	push 	{r1}
	orr     r1, #2_11111111						;Habilitar funcionalidade digital na DEN os bits 0 e 1
	STR     R1, [R4]

	ldr r4, =GPIO_PORTM_AHB_DATA_R
	ldr r1, =GPIO_PORTK_AHB_DATA_R
	
	ldr r2, [r4]
	ldr r3, [r1]

	and r0, #2_11111111

	; RS=1, RW=0, EN=1 (envia dado)
	bic r2, #2_00000010
	orr r2, #2_00000101	
	str r2, [r4]
	
	; Escreve o comando na porta de dados do display
	orr r3, r0
	eor r0, #2_11111111
	bic r3, r0
	str r3, [r1]
	
	push {r0, r1, r3, lr}
	mov r0, #1
	bl SysTick_Wait1ms
	pop {r0, r1, r3, lr}
	
	; EN=0 (da clock no display)
	bic r2, #2_00000100
	str r2, [r4]
	
	LDR R4, =GPIO_PORTK_AHB_DIR_R
	pop {r1}
	str r1, [r4]
	
	push {lr}
	bl Wait_For_Display
	pop {lr}
	
	pop {r0-r4}
	bx lr
	
	ALIGN
	END