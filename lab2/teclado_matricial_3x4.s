; Biblioteca em assembly para uso de teclado matricial 3x4 com a PAT DAELN e Tiva C TM4C129
; Nicolas Abril e Lucca Rawlyk


; Defini��es de constantes de GPIO

; Defini��es dos Registradores Gerais
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
		export Varre_Teclado


; Prepara o teclado para uso (configura GPIO e seta as constantes)
; L - Linha, C - Coluna
Init_Teclado
; 1. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO,
; ap�s isso verificar no PRGPIO se a porta est� pronta para uso.
; enable clock to GPIOF at clock gating register
	push {r0-r2}
	LDR		R0, =SYSCTL_RCGCGPIO_R
	ldr		r1, [r0]
	orr		r1, #GPIO_PORTL	
	orr 	r1, #GPIO_PORTC
	str 	r1, [r0]

	LDR     R0, =SYSCTL_PRGPIO_R			;Carrega o endere�o do PRGPIO para esperar os GPIO ficarem prontos
EsperaGPIO
	LDR     R1, [R0]						;L� da mem�ria o conte�do do endere�o do registrador
	mov 	r2, r1
	orr		R2, #GPIO_PORTL                 ;Seta o bit da porta A
	ORR     R2, #GPIO_PORTC					;Seta o bit da porta B, fazendo com OR
	TST     R1, R2							;ANDS de R1 com R2
	BEQ     EsperaGPIO					    ;Se o flag Z=1, volta para o la�o. Sen�o continua executando
	
; 2. Limpar o AMSEL para desabilitar a anal�gica
    LDR     R0, =GPIO_PORTL_AHB_AMSEL_R     ;Carrega o R0 com o endere�o do AMSEL para a porta J
	LDR		r1, [r0]
	bic 	r1, #0x0F
    STR     R1, [R0]	
	;Colocar 0 no registrador para desabilitar a fun��o anal�gica
    LDR     R0, =GPIO_PORTC_AHB_AMSEL_R     ;Carrega o R0 com o endere�o do AMSEL para a porta J
	ldr		r1, [r0]
	bic		r1, #0xf0
    STR     R1, [R0]					    ;Colocar 0 no registrador para selecionar o modo GPIO
	
; 3. Limpar PCTL para selecionar o GPIO
    LDR     R0, =GPIO_PORTL_AHB_PCTL_R		;Carrega o R0 com o endere�o do PCTL para a porta J
    LDR		r1, [r0]
	mov		r2, #0
	movt	r2, #0xffff
	and 	r1, r2
    STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTC_AHB_PCTL_R		;Carrega o R0 com o endere�o do PCTL para a porta J
    ldr		r1, [r0]
	movt	r1, #0x0000
    STR     R1, [R0]
	
; 4. DIR para 0 se for entrada, 1 se for sa�da	
	LDR     R0, =GPIO_PORTC_AHB_DIR_R		;Carrega o R0 com o endere�o do DIR para a porta N
	ldr		r1, [r0]
	bic     R1, #0xf0    		 			;Entrada do teclado (4 colunas)
    STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTL_AHB_DIR_R		;Carrega o R0 com o endere�o do DIR para a porta N
	ldr		r1, [r0]
	orr     R1, #0x0f     					;Saida do teclado (3 linhas e GND)
    STR     R1, [R0]
	
; 5. Limpar os bits AFSEL para 0 para selecionar GPIO sem fun��o alternativa
	LDR     R0, =GPIO_PORTC_AHB_AFSEL_R		;Carrega o endere�o do AFSEL da porta N
	ldr		r1, [r0]
	bic		r1, #0xf0
	STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTL_AHB_AFSEL_R		;Carrega o endere�o do AFSEL da porta N
	ldr		r1, [r0]
	bic 	r1, #0x0f
	STR     R1, [R0]

; 6. Setar os bits de DEN para habilitar I/O digital
	LDR     R0, =GPIO_PORTC_AHB_DEN_R			;Carrega o endere�o do DEN
	LDR     R1, [R0]							;Ler da mem�ria o registrador GPIO_PORTN_AHB_DEN_R
	orr     r1, #0xf0							;Habilitar funcionalidade digital na DEN os bits 0 e 1
	STR     R1, [R0]
	
	LDR     R0, =GPIO_PORTL_AHB_DEN_R			;Carrega o endere�o do DEN
	LDR     R1, [R0]							;Ler da mem�ria o registrador GPIO_PORTN_AHB_DEN_R
	orr     R1, #0x0f						;Habilitar funcionalidade digital na DEN os bits 0 e 1
	STR     R1, [R0]
	
; Desliga as linhas e ativa o GND
	ldr r0, =GPIO_PORTL_AHB_DATA_R
	ldr r1, [r0]
	bic r1, #2_1111
	str r1, [r0]
	
	pop {r0-r2}
	bx lr
	
; Retorna em r0 a tecla pressionada (prioridade para a ordem de varredura)
Varre_Teclado
	mov r0, #1
	push {lr}
	bl Varre_Linha
	pop {lr}
	cbz r0, Linha_1_Nao_Pressionada
	bx lr

Linha_1_Nao_Pressionada
	mov r0, #2
	push {lr}
	bl Varre_Linha
	pop {lr}
	cbz r0, Linha_2_Nao_Pressionada
	mov r0, #0
	bx lr

Linha_2_Nao_Pressionada
	mov r0, #3
	push {lr}
	bl Varre_Linha
	pop {lr}
	cbz r0, Nenhuma_Linha_Pressionada
	bx lr

Nenhuma_Linha_Pressionada
	mov r0, #0
	bx lr

; Recebe o numero da linha a varrer(1,2,3) e retorna a coluna pressionada(1,2,3,4)
; Retorna 0 se nenhum botao pressionado
; Entrada em R0, saida em R0
; Nao testa entradas nem saidas
Varre_Linha
	push {r1, r2, r3, r4}  
	sub r0, #1
	mov r4, r0	; r4 é o numero da linha comecando em 0
	mov r2, #1
	lsl r2, r0	; r2 e o bit da linha a ser lida
	
	; Ativa a linha a ser varrida e desativa as outras
	LDR     R0, =GPIO_PORTL_AHB_DEN_R		
	ldr		r1, [r0]
	orr     R1, r2
	mov		r3, #0x07
	sub		r3, r2
	bic		r1, r3
    STR     R1, [R0]

	; Escreve 1 na linha a ser lida
	ldr r0, =GPIO_PORTL_AHB_DATA_R
	ldr r1, [r0]
	orr r1, r2
	str r1, [r0]

	; Le os botoes
	push {lr}
	bl Varre_Colunas
	pop{lr}
	cbz r0, Linha_Nao_Pressionada
	mov r3, #4
	mul r4, r3			;r3 é numero de colunas em uma linha
	add r0, r4, r0
	pop {r1,r2,r3,r4}
	bx lr
Linha_Nao_Pressionada
	mov r0, #0
	pop {r1,r2,r3,r4}
	bx lr 

; Escreve em r0 o valor da coluna pressionada
Varre_Colunas
	push{r1, r2}

	ldr r0, =GPIO_PORTC_AHB_DATA_R
	ldr r1, [r0]

	and r2, r1, #2_00010000
	cbz r2, Coluna_1_Nao_Pressionada
	mov r0, #1
	pop {r1, r2}
	bx lr
Coluna_1_Nao_Pressionada
	and r2, r1, #2_00100000
	cbz r2, Coluna_2_Nao_Pressionada
	mov r0, #2
	pop {r1, r2}
	bx lr
Coluna_2_Nao_Pressionada
	and r2, r1, #2_01000000
	cbz r2, Coluna_3_Nao_Pressionada
	mov r0, #3
	pop {r1, r2}
	bx lr
Coluna_3_Nao_Pressionada
	and r2, r1, #2_10000000
	cbz r2, Nenhuma_Coluna_Pressionada
	mov r0, #4
	pop {r1, r2}
	bx lr
Nenhuma_Coluna_Pressionada
	mov r0, #0

	pop {r1, r2}
	bx lr


	ALIGN
	END