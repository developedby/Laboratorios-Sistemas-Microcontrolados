// main.c
// Desenvolvido para a placa EK-TM4C1294XL
// Verifica o estado da chave USR_SW2 e acende os LEDs 1 e 2 caso esteja pressionada
// Prof. Guilherme Peron

#include <stdint.h>

void PLL_Init(void);
void SysTick_Init(void);
void SysTick_Wait1ms(uint32_t delay);

void GPIO_Init(void);
uint32_t PortJ_Input(void);
void PortN_Output(uint32_t leds);
void Init_Display(void);

void Init_Teclado(void);
int Varre_Teclado(void);

void Init_Motor_DC(void);
void Move_Motor_DC (int vel);

void Init_Potenciometro (void);
int Le_Potenciometro (void);

void Display_Clean (void);
void Display_Print (const char* mensagem, int linha, int coluna);

int main(void)
{
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	Init_Display();
	Init_Teclado();
	Init_Motor_DC();
	Init_Potenciometro();
	
	int pot;
	while (1)
	{
		pot = Le_Potenciometro();
		
		Move_Motor_DC(100);
	}
	
}

