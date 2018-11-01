// Biblioteca para mover motor de passo com a PAT DAELN e Tiva C TM4C129
// Nicolas Abril e Lucca Rawlyk
#include <stdint.h>
#include "tm4c1294ncpdt.h"

typedef enum tipo_passo {PASSO_COMPLETO, MEIO_PASSO} tipo_passo_t;

void Init_Motor_Passo ();
float Move_Motor_Passo (float pos_motor_desejada, float pos_motor_atual);
int Calcula_Novo_Estado_Motor (int estado_anterior, tipo_passo_t tipo_passo);
int Da_Passo (int estado_anterior, tipo_passo_t tipo_passo);

int Da_Passo(int estado_anterior, tipo_passo_t tipo_passo)
{
	int novo_estado = Calcula_Novo_Estado_Motor (estado_anterior, tipo_passo);
	GPIO_PORTH_AHB_DATA_R &= 0xfffffff0; 
	GPIO_PORTH_AHB_DATA_R |= novo_estado;
	return novo_estado;
}


int Calcula_Novo_Estado_Motor (int estado_anterior, tipo_passo_t tipo_passo)
{
	int novo_estado = estado_anterior;
	
	if (tipo_passo == MEIO_PASSO)
	{
		// Se estava em um passo inteiro, nao e divisivel por 3
		if (estado_anterior % 3)
		{
			novo_estado = (novo_estado << 1) + novo_estado;
		}
		else
		{
			novo_estado = novo_estado & (novo_estado << 1);
		}		
	}
	else if (tipo_passo == PASSO_COMPLETO)
	{
		novo_estado <<= 1;
	}

	if (novo_estado > 1<<3)
	{
		novo_estado = novo_estado - (1<<4) + 1;
	}
	return novo_estado;
}