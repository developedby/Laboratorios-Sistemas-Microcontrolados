// main.c
// Desenvolvido para a placa EK-TM4C1294XL
// Verifica o estado da chave USR_SW2 e acende os LEDs 1 e 2 caso esteja pressionada
// Prof. Guilherme Peron

#include <stdint.h>

#include "motor_dc.c"

void PLL_Init(void);
void SysTick_Init(void);
void SysTick_Wait1ms(uint32_t delay);
void GPIO_Init(void);
uint32_t PortJ_Input(void);
void PortN_Output(uint32_t leds);
void Init_Display();
int Varre_Teclado(void);
void Init_Motor_DC ();
void Move_Motor_DC (int vel);
void Timer0A_Handler ();
void Init_Magnetometro ();


void Display_Clean ();
void Display_Print (const char* mensagem, int linha, int coluna);

int main(void)
{
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	Init_Display();
	Init_Magnetometro();
	
}


