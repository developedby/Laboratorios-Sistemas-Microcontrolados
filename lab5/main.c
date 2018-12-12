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

void Init_Display (void);
void Display_Send_Data (int byte);
void Display_Send_Instruction (int byte);

int Varre_Teclado(void);
void Init_Magnetometro ();

void Display_Clean (void);
void Display_Print (const char* mensagem, int linha, int coluna);
void Display_Erro (void);

int main(void)
{
	PLL_Init();
	SysTick_Init();
	GPIO_Init();
	Init_Display();
	Init_Magnetometro();
	
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
