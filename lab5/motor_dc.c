// Biblioteca para mover motor DC com a PAT DAELN e Tiva C TM4C129
// Nicolas Abril e Lucca Rawlyk
#include <stdint.h>
#include <stdlib.h>
#include "tm4c1294ncpdt.h"

void Init_Motor_DC ();
void Move_Motor_DC (int vel);
void Timer0A_Handler ();


#define SYS_CLOCK 				80000000		//80 Mhz
#define PWM_CLOCK					10000				//10 kHz (100 clocks por pulso)
#define MOTOR_INPUT_PORT	GPIO_PORTE_AHB_DATA_R	
#define MOTOR_INPUT_A			0
#define MOTOR_INPUT_B			1
#define MOTOR_PWM_PORT		GPIO_PORTF_AHB_DATA_R
#define MOTOR_PWM_PIN			2

int motor_pwm = 0;
uint32_t contador_pwm = 0; 

// Inicializa o sistema para usar o motor DC em P5.2 e P5.3 da PAT
void Init_Motor_DC ()
{
	// Configura o timer do PWM do motor
	SYSCTL_RCGCTIMER_R |= SYSCTL_RCGCTIMER_R0;																				// Seleciona clk do processador poara o timer
	
	while (!(SYSCTL_PRTIMER_R & SYSCTL_PRTIMER_R0))																		// Espera o timer estar pronto
		;
	
	TIMER0_CTL_R &= ~(TIMER_CTL_TAEN + TIMER_CTL_TBEN);																// Desabilita o timer a pra poder mudar ele
	TIMER0_CFG_R = (TIMER0_CFG_R & (~TIMER_CFG_M)) | TIMER_CFG_32_BIT_TIMER;					// Seleciona timer de 32bits (concatenado)
	TIMER0_TAMR_R = TIMER_TAMR_TAMR_PERIOD;																						// Seleciona modod periodico de timer
	TIMER0_TAILR_R = SYS_CLOCK / PWM_CLOCK;																						// Carrega o comparador para o clk do pwm
	TIMER0_ICR_R = TIMER_ICR_TATOCINT;																								// Limpa a interrupcao do timer
	TIMER0_IMR_R = TIMER_IMR_TATOIM;																									// Seleciona a interrupcao para o modo de funcionatmento
	NVIC_PRI4_R = (NVIC_PRI4_R & (~NVIC_PRI4_INT19_M)) | (1 << NVIC_PRI4_INT19_S);		// Prioridade 0 para a interrupção
	NVIC_EN0_R |= (1 << 19);																													// Habilita a interrupção 19 (timer0a)
	TIMER0_CTL_R |= (TIMER_CTL_TAEN + TIMER_CTL_TBEN);																// Habilita o timer de volta
	
	// Liga as saidas
	//1a. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO
	SYSCTL_RCGCGPIO_R |= SYSCTL_PPGPIO_P4 + SYSCTL_PPGPIO_P5;
	//1b.   após isso verificar no PRGPIO se a porta está pronta para uso.
  while((SYSCTL_PRGPIO_R & (SYSCTL_PPGPIO_P4 + SYSCTL_PPGPIO_P5) ) != (SYSCTL_PPGPIO_P4 + SYSCTL_PPGPIO_P5) ){};
	
	// 2. Limpar o AMSEL para desabilitar a analógica
	GPIO_PORTE_AHB_AMSEL_R &= ~(MOTOR_INPUT_A + MOTOR_INPUT_B);
	GPIO_PORTF_AHB_AMSEL_R &= ~(MOTOR_PWM_PIN);
		
	// 3. Limpar PCTL para selecionar o GPIO
	GPIO_PORTE_AHB_PCTL_R &= ~(MOTOR_INPUT_A + MOTOR_INPUT_B);
	GPIO_PORTF_AHB_PCTL_R &= ~(MOTOR_PWM_PIN);

	// 4. DIR para 0 se for entrada, 1 se for saída
	GPIO_PORTE_AHB_DIR_R |= MOTOR_INPUT_A + MOTOR_INPUT_B;
	GPIO_PORTF_AHB_DIR_R |= MOTOR_PWM_PIN;
		
	// 5. Limpar os bits AFSEL para 0 para selecionar GPIO sem função alternativa	
	GPIO_PORTE_AHB_AFSEL_R &= ~(MOTOR_INPUT_A + MOTOR_INPUT_B);
	GPIO_PORTF_AHB_AFSEL_R &= ~(MOTOR_PWM_PIN);
		
	// 6. Setar os bits de DEN para habilitar I/O digital	
	GPIO_PORTE_AHB_DEN_R |= MOTOR_INPUT_A + MOTOR_INPUT_B;
	GPIO_PORTF_AHB_DEN_R |= MOTOR_PWM_PIN;
	
	// Para o motor
	Move_Motor_DC(0);
}

// signal(vel) é a direcao e abs(vel) é o duty cycle do pwm
// abs(vel) > 100 tem o mesmo efeito que vel=100
void Move_Motor_DC (int vel)
{

	MOTOR_INPUT_PORT = MOTOR_INPUT_PORT & ~((1<<MOTOR_INPUT_A) + (1<<MOTOR_INPUT_B));
	if (vel > 0)
	{
		MOTOR_INPUT_PORT = (MOTOR_INPUT_PORT & ~((1<<MOTOR_INPUT_B))) | (1<<MOTOR_INPUT_A);	// vai para a frente; A=1, B=0
	}
	else if (vel < 0)
	{
		MOTOR_INPUT_PORT = (MOTOR_INPUT_PORT & ~((1<<MOTOR_INPUT_A))) | (1<<MOTOR_INPUT_B);	// vai para tras; 		A=0, B=1
	}
	else //vel == 0
	{
		MOTOR_INPUT_PORT = (MOTOR_INPUT_PORT & ~((1<<MOTOR_INPUT_A) + (1<<MOTOR_INPUT_B)));	// solta o motor;			A=0, B=0
	}
	
	motor_pwm = abs(vel);

}

void Timer0A_Handler ()
{
	TIMER0_ICR_R = TIMER_ICR_TATOCINT;
	contador_pwm++;
	if (contador_pwm == motor_pwm)
	{
		//saida pwm = 0
		MOTOR_PWM_PORT &= ~MOTOR_PWM_PIN;
	}
	if (contador_pwm > 100)
	{
		//saida pwm = 1
		MOTOR_PWM_PORT |= MOTOR_PWM_PIN;
	}
}