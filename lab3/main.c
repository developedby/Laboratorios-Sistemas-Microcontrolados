// main.c
// Desenvolvido para a placa EK-TM4C1294XL
// Verifica o estado da chave USR_SW2 e acende os LEDs 1 e 2 caso esteja pressionada
// Prof. Guilherme Peron

#include <stdint.h>

#include "motor_passo.c"

void PLL_Init(void);
void SysTick_Init(void);
void SysTick_Wait1ms(uint32_t delay);
void GPIO_Init(void);
uint32_t PortJ_Input(void);
void PortN_Output(uint32_t leds);
void Init_Display();
void Init_Teclado();
int Varre_Teclado(void);

typedef enum {COFRE_ABERTO, COFRE_FECHADO, COFRE_ABRINDO, COFRE_FECHANDO} estado;

void Display_Clean ();
void Display_Print (const char* mensagem, int linha, int coluna);

int main(void)
{
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	Init_Display();
	Init_Teclado();

	const int senha_mestra[4] = {1, 2, 3, 4};
	int senha_atual[4] = {-1, -1, -1, -1};
	int senha_pressionada[4] = {-1, -1, -1, -1};

	estado estado_cofre = COFRE_ABERTO;
	float pos_motor = 0;
	int caracteres_inseridos_senha = 0;
	int botao_pressionado = 0;
	Display_Clean();
	Display_Print("Cofre Aberto", 0, 0);
	Display_Print("Digite Nova Senha", 0, 1);
	pos_motor = Move_Motor_Passo(0, pos_motor);

	while (1)
	{
		switch (estado_cofre)
		{
			case COFRE_ABERTO:
				botao_pressionado = Varre_Teclado();
				if (botao_pressionado <= 9 || botao_pressionado > 0)
				{
					caracteres_inseridos_senha++;
					if (caracteres_inseridos_senha <= 4)
					{
						senha_atual[caracteres_inseridos_senha-1] = botao_pressionado;
						SysTick_Wait1ms(300);
					}
				}
				else
				{
					if (botao_pressionado == 16)
					{
						if (caracteres_inseridos_senha > 4)
						{
							estado_cofre = COFRE_ABRINDO;
							caracteres_inseridos_senha = 0;
						}
						else
						{
							SysTick_Wait1ms(300);
						}
					}
				}
				break;

			case COFRE_FECHANDO:
				Display_Clean();
				Display_Print("Cofre Fechando", 0, 0);
				SysTick_Wait1ms(1000);
				pos_motor = Move_Motor_Passo(180, pos_motor);
				estado_cofre = COFRE_FECHADO;

				Display_Clean();
				Display_Print("Cofre Fechado", 0, 0);
				break;

			case COFRE_FECHADO:
				botao_pressionado = Varre_Teclado();
				if (botao_pressionado <= 9 || botao_pressionado > 0)
				{
					caracteres_inseridos_senha++;
					if (caracteres_inseridos_senha <= 4)
					{
						senha_pressionada[caracteres_inseridos_senha-1] = botao_pressionado;
						SysTick_Wait1ms(300);
					}
					else
					{
						caracteres_inseridos_senha = 0;
						if (senha_pressionada[0] == senha_atual[0] && 
							senha_pressionada[1] == senha_atual[1] && 
							senha_pressionada[2] == senha_atual[2] && 
							senha_pressionada[3] == senha_atual[3])
						{
							estado_cofre = COFRE_ABRINDO;
						}
						else
						{
							Display_Clean();
							Display_Print("Cofre Fechado", 0, 0);
							Display_Print("Senha Incorreta", 0, 1);
						}
						senha_pressionada[0]=-1;
						senha_pressionada[1]=-1;
						senha_pressionada[2]=-1;
						senha_pressionada[3]=-1;
					}
				}
				break;

			case COFRE_ABRINDO:
				senha_atual[0]=-1;
				senha_atual[1]=-1;
				senha_atual[2]=-1;
				senha_atual[3]=-1;
				Display_Clean();
				Display_Print("Cofre Abrindo", 0, 0);
				pos_motor = Move_Motor_Passo(0, pos_motor);
				estado_cofre = COFRE_ABERTO;

				Display_Clean();
				Display_Print("Cofre Aberto", 0, 0);
				Display_Print("Digite Nova Senha", 0, 1);
				break;
		}     
	}
}


