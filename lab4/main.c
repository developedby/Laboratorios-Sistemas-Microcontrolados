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
int Mapeia_Tecla(int);

void Init_Motor_DC(void);
void Move_Motor_DC (int vel);

void Init_Potenciometro (void);
int Le_Potenciometro (void);

void Display_Clean (void);
void Display_Print (const char* mensagem, int linha, int coluna);

#define POT_MAX 0x7FF

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
	int tecla;
	int vel_motor;
	while (1)
	{
		tecla = Mapeia_Tecla(Varre_Teclado());
		if(tecla ==  '1')
		{
			int vel = 0, tecla_up = 0;
			while((tecla = Mapeia_Tecla(Varre_Teclado())) != '2')
			{
				while((tecla = Mapeia_Tecla(Varre_Teclado())) != 0)
					tecla_up = tecla;
				if(tecla_up == '4')
				{	
					vel += 20;
					tecla_up = 0;
				}
				if(tecla_up == '5')
				{	
					vel -= 20;
					tecla_up = 0;
				}
				if(vel > 100)
					vel = 100;
				if(vel < -100)
					vel = -100;
				Move_Motor_DC(vel);
			}
		}
		pot = Le_Potenciometro();
		vel_motor = ((pot-POT_MAX)*100)/POT_MAX;
		Move_Motor_DC(vel_motor);
	}
	
}


