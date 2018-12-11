// main.c
// Desenvolvido para a placa EK-TM4C1294XL
// Verifica o estado da chave USR_SW2 e acende os LEDs 1 e 2 caso esteja pressionada
// Prof. Guilherme Peron

#include <stdint.h>
#include <math.h>
#include <stdio.h>

void PLL_Init(void);
void SysTick_Init(void);
void SysTick_Wait1ms(uint32_t delay);

void GPIO_Init(void);
uint32_t PortJ_Input(void);
void PortN_Output(uint32_t leds);

void Init_Teclado(void);
int Varre_Teclado(void);
int Mapeia_Tecla(int);

void Init_Motor_DC(void);
void Move_Motor_DC (int vel);

void Init_Potenciometro (void);
int Le_Potenciometro (void);

void Init_Display (void);
void Display_Send_Data (int byte);
void Display_Send_Instruction (int byte);

void Display_Clean (void);
void Display_Print (const char* mensagem, int linha, int coluna);
void Display_Motor (int vel, int sen);
void Display_Erro (void);

#define POT_MAX 0xFFF

typedef enum estado_t {PARADO, TECLADO_SENTIDO, TECLADO_VELOCIDADE, POT_SENTIDO, POT_VELOCIDADE} estado_t;

int main(void)
{
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	Init_Display();
	Init_Teclado();
	Init_Motor_DC();
	Init_Potenciometro();
	
	int tecla = 0;
	int vel_motor = 0;
	int sentido = 0;
	int volta_menu = 0;
	estado_t estado = PARADO;
	while (1)
	{
		switch (estado)
		{
			case PARADO:
			{
				vel_motor = 0;
				sentido = 0;
				Move_Motor_DC(0);
				Display_Clean();
				Display_Print("Motor Parado", 1, 1);
				Display_Print("1:Teclad 2:Pot", 2, 1);
				for (tecla = Mapeia_Tecla(Varre_Teclado()); tecla != '2' && tecla != '1'; tecla = Mapeia_Tecla(Varre_Teclado()))
					;
				if (tecla == '1')
					estado = TECLADO_SENTIDO;
				else if (tecla == '2')
					estado = POT_SENTIDO;
				else
				{
					Display_Erro();
				}
				break;
			}		
			case TECLADO_SENTIDO:
			{
				Display_Clean();
				Display_Print("Sentido motor", 1, 1);
				Display_Print("*:Hor #:Anti-hor", 2, 1);
				for (tecla = Mapeia_Tecla(Varre_Teclado()); tecla != '*' && tecla != '#'; tecla = Mapeia_Tecla(Varre_Teclado()))
				{
					volta_menu = !(PortJ_Input() & 1);
					if (volta_menu)
						break;
				}
				if (volta_menu)
				{
					estado = PARADO;
				}
				else
				{
					if (tecla == '*')
						sentido = 1;
					else if (tecla == '#')
						sentido = -1;
					else
					{
						Display_Erro();
					}
					estado = TECLADO_VELOCIDADE;
				}
				break;
			}
			case TECLADO_VELOCIDADE:
			{
				Display_Motor(vel_motor, sentido);
				volta_menu = 0;
				while (!volta_menu)
				{
					tecla = Mapeia_Tecla(Varre_Teclado());
					if (tecla != 0)
					{				
						if (tecla == '*')
							sentido = 1;
						else if (tecla == '#')
							sentido = -1;
						else if (tecla == '0')
						{
							vel_motor = 0;
						}
						else if (tecla == '1')
						{
							vel_motor = 50;
						}
						else if (tecla == '2')
						{
							vel_motor = 60;
						}
						else if (tecla == '3')
						{
							vel_motor = 70;
						}
						else if (tecla == '4')
						{
							vel_motor = 80;
						}
						else if (tecla == '5')
						{
							vel_motor = 90;
						}
						else if (tecla == '6')
						{
							vel_motor = 100;
						}
						
						Move_Motor_DC(sentido*vel_motor);
						Display_Motor(vel_motor, sentido);
					}
					
					volta_menu = !(PortJ_Input() & 1);
				}
				estado = PARADO;
				break;
			}
			case POT_SENTIDO:
			{
				Display_Clean();
				Display_Print("Sentido motor", 1, 1);
				Display_Print("*:Hor #:Anti-hor", 2, 1);
				for (tecla = Mapeia_Tecla(Varre_Teclado()); tecla != '*' && tecla != '#'; tecla = Mapeia_Tecla(Varre_Teclado()))
				{
					volta_menu = !(PortJ_Input() & 1);
					if (volta_menu)
						break;
				}
				if (volta_menu)
				{
					estado = PARADO;
				}
				else
				{
					if (tecla == '*')
						sentido = 1;
					else if (tecla == '#')
						sentido = -1;
					else
					{
						Display_Erro();
					}
					estado = POT_VELOCIDADE;
				}
				break;
			}
			case POT_VELOCIDADE:
			{
				Display_Motor(vel_motor, sentido);
				volta_menu = 0;
				int vel_antiga = vel_motor;
				while (!volta_menu)
				{
					tecla = Mapeia_Tecla(Varre_Teclado());		
					if (tecla == '*')
						sentido = 1;
					else if (tecla == '#')
						sentido = -1;

					vel_motor = (100*Le_Potenciometro())/POT_MAX;
					if(vel_antiga != vel_motor)
					{
						Move_Motor_DC(sentido*vel_motor);
						Display_Motor(vel_motor, sentido);
						vel_antiga = vel_motor;
					}
					volta_menu = !(PortJ_Input() & 1);
				}
				estado = PARADO;
				break;
			}
			default:
				Display_Erro();
				break;	
		}
		/*
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
	*/
	}
}

void Display_Motor (int vel, int sen)
{
	char str[5];
	Display_Clean();
	Display_Print("Vel motor: ", 1, 1);
	if (sprintf(str, "%d", vel) < 0)
		Display_Erro();
	Display_Print(str, 1, 11);
	Display_Print("Sentido: ", 2, 1);
	if (sen > 0)
		Display_Print("hor", 2, 9);
	else if (sen < 0)
		Display_Print("a-hor", 2, 9);
}

void Display_Erro()
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

void Display_Clean ()
{
	Display_Send_Instruction(0x01);
}
