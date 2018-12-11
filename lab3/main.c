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
int Mapeia_Tecla(int tecla);

typedef enum tipo_passo {PASSO_COMPLETO, MEIO_PASSO} tipo_passo_t;

#define N_PASSOS 96
#define MOTOR_COFRE_ABERTO 0
#define MOTOR_COFRE_FECHADO N_PASSOS/2
#define TAMANHO_SENHA 4

typedef struct
{
	unsigned int n_passos;
	int pos_atual;
	int estado;
	tipo_passo_t tipo_passo;
} motor_passo_t;

motor_passo_t Init_Motor_Passo (unsigned int const n_passos, tipo_passo_t const tipo_passo);
void Move_Motor_Passo (int pos_motor_desejada, motor_passo_t* motor, int sentido);

typedef enum {COFRE_ABERTO, COFRE_FECHADO, COFRE_ABRINDO, COFRE_FECHANDO, TRAVADO, SENHA_MESTRA} estado;

void Display_Send_Instruction (int byte);
void Display_Send_Data (int byte);
void Display_Clean (void);
void Display_Print (const char* mensagem, int linha, int coluna);
void Display_Erro (void);

int travado = 0;

int main(void)
{
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	Init_Display();
	Init_Teclado();
	motor_passo_t motor = Init_Motor_Passo(200, MEIO_PASSO);
	char const senha_mestra[TAMANHO_SENHA+1] = {'1', '2', '3', '4', '\0'};
	char senha_atual[TAMANHO_SENHA+1] = {' ', ' ', ' ', ' ', '\0'};
	char senha_pressionada[TAMANHO_SENHA+1] = {' ', ' ', ' ', ' ', '\0'};
	int n_tentativas_erradas = 0;
	estado estado_cofre = COFRE_ABERTO;
	int caracteres_inseridos_senha = 0;
	int botao_pressionado = 0;
	
	Display_Clean();
	Display_Print("Cofre Aberto", 1, 1);
	Display_Print("Nova Senha: ", 2, 1);

	while (1)
	{
		switch (estado_cofre)
		{
			case COFRE_ABERTO:
				botao_pressionado = Mapeia_Tecla(Varre_Teclado());
				if (botao_pressionado <= '9' && botao_pressionado >= '0')
				{
					caracteres_inseridos_senha++;
					if (caracteres_inseridos_senha <= TAMANHO_SENHA)
					{
						senha_atual[caracteres_inseridos_senha-1] = botao_pressionado;
						Display_Print(senha_atual, 2, 13);
						SysTick_Wait1ms(500);
					}
				}
				else
				{
					if (botao_pressionado == '#')
					{
						if (caracteres_inseridos_senha >= TAMANHO_SENHA)
						{
							estado_cofre = COFRE_FECHANDO;
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
				Display_Print("Cofre Fechando", 1, 1);
				SysTick_Wait1ms(1000);
				Move_Motor_Passo(MOTOR_COFRE_FECHADO, &motor, 1);
				estado_cofre = COFRE_FECHADO;
				n_tentativas_erradas = 0;
				Display_Clean();
				Display_Print("Cofre Fechado", 1, 1);
				break;

			case COFRE_FECHADO:
				botao_pressionado = Mapeia_Tecla(Varre_Teclado());
				if (botao_pressionado <= '9' && botao_pressionado >= '0')
				{
					if (caracteres_inseridos_senha < TAMANHO_SENHA)
					{
						senha_pressionada[caracteres_inseridos_senha] = botao_pressionado;
						caracteres_inseridos_senha++;
						Display_Print("            ", 2, 1);
						Display_Print(senha_pressionada, 2, 13);
						SysTick_Wait1ms(500);
					}
					if (caracteres_inseridos_senha >= TAMANHO_SENHA)
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
							Display_Print("Cofre Fechado", 1, 1);
							Display_Print("Senha Incorreta", 2, 1);
							n_tentativas_erradas++;
							if (n_tentativas_erradas >= 3)
							{
								estado_cofre = TRAVADO;
							}
						}
						senha_pressionada[0]=' ';
						senha_pressionada[1]=' ';
						senha_pressionada[2]=' ';
						senha_pressionada[3]=' ';
					}
				}
				break;

			case TRAVADO:
				travado = 1;
				Display_Clean();
				Display_Print("Errou de mais", 1, 1);
				Display_Print("Cofre travado", 2, 1);
				while(travado)
					;
				senha_pressionada[0]=' ';
				senha_pressionada[1]=' ';
				senha_pressionada[2]=' ';
				senha_pressionada[3]=' ';
				caracteres_inseridos_senha = 0;
				Display_Clean();
				Display_Print("Senha mestre:", 1, 1);
				estado_cofre = SENHA_MESTRA;
				break;
				
			case SENHA_MESTRA:
				botao_pressionado = Mapeia_Tecla(Varre_Teclado());
				if (botao_pressionado <= '9' && botao_pressionado >= '0')
				{
					if (caracteres_inseridos_senha < TAMANHO_SENHA)
					{
						senha_pressionada[caracteres_inseridos_senha] = botao_pressionado;
						caracteres_inseridos_senha++;
						Display_Print("            ", 2, 1);
						Display_Print(senha_pressionada, 2, 13);
						SysTick_Wait1ms(500);
					}
					if (caracteres_inseridos_senha >= TAMANHO_SENHA)
					{
						caracteres_inseridos_senha = 0;
						if (senha_pressionada[0] == senha_mestra[0] && 
							senha_pressionada[1] == senha_mestra[1] && 
							senha_pressionada[2] == senha_mestra[2] && 
							senha_pressionada[3] == senha_mestra[3])
						{
							estado_cofre = COFRE_ABRINDO;
						}
						else
						{
							estado_cofre = TRAVADO;
						}
						senha_pressionada[0]=' ';
						senha_pressionada[1]=' ';
						senha_pressionada[2]=' ';
						senha_pressionada[3]=' ';
					}
				}
				break;
				
			case COFRE_ABRINDO:
				senha_atual[0]=' ';
				senha_atual[1]=' ';
				senha_atual[2]=' ';
				senha_atual[3]=' ';
				senha_pressionada[0]=' ';
				senha_pressionada[1]=' ';
				senha_pressionada[2]=' ';
				senha_pressionada[3]=' ';
				Display_Clean();
				Display_Print("Cofre Abrindo", 1, 1);
				Move_Motor_Passo(MOTOR_COFRE_ABERTO, &motor, -1);
				estado_cofre = COFRE_ABERTO;

				Display_Clean();
				Display_Print("Cofre Aberto", 1, 1);
			  Display_Print("Nova Senha:", 2, 1);
				break;
		}     
	}
}

void Display_Erro(void)
{
	Display_Clean();
	Display_Print("Bugou", 1, 1);
	while(1){;}
}

void Display_Print (const char* mensagem, int linha, int coluna)
{
	int addr_cursor = 0x80 + (0x40*(linha-1)); // so para display de 2 linhas, indice comeca em 1
	addr_cursor	+= coluna-1;
	Display_Send_Instruction(addr_cursor);
	for (int i = 0; mensagem[i] != '\0'; i++)
	{
		Display_Send_Data(mensagem[i]);
	}
}

void Display_Clean (void)
{
	Display_Send_Instruction(0x01);
}

