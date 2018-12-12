// Biblioteca para mover motor de passo com a PAT DAELN e Tiva C TM4C129
// Nicolas Abril e Lucca Rawlyk

#ifndef MOTOR_PASSO_LIB_
#define MOTOR_PASSO_LIB_

#include <stdint.h>
#include "tm4c1294ncpdt.h"

void SysTick_Wait1ms (uint32_t);

typedef enum tipo_passo {PASSO_COMPLETO, MEIO_PASSO} tipo_passo_t;

typedef struct
{
	unsigned int n_passos;
	int pos_atual;
	int estado;
	tipo_passo_t tipo_passo;
} motor_passo_t;

motor_passo_t Init_Motor_Passo (unsigned int const n_passos, tipo_passo_t const tipo_passo);
void Move_Motor_Passo (int pos_motor_desejada, motor_passo_t* motor, int sentido);
int Calcula_Novo_Estado_Motor (int estado_anterior, tipo_passo_t tipo_passo, int sentido);
int Da_Passo (int estado_anterior, tipo_passo_t tipo_passo, int sentido);

motor_passo_t Init_Motor_Passo (unsigned int const n_passos, tipo_passo_t const tipo_passo)
{
	//Configura porta
	SYSCTL_RCGCGPIO_R |= SYSCTL_PPGPIO_P7;
  while((SYSCTL_PRGPIO_R & (SYSCTL_PPGPIO_P7) ) != (SYSCTL_PPGPIO_P7) ){};
	GPIO_PORTH_AHB_AMSEL_R = 0x00;
	GPIO_PORTH_AHB_PCTL_R = 0x00;
	GPIO_PORTH_AHB_DIR_R = 0x0F;//in1-in4 do motor de passo
	GPIO_PORTH_AHB_AFSEL_R = 0x00;
	GPIO_PORTH_AHB_DEN_R = 0x0F;
	
	motor_passo_t motor = {n_passos, 0, 0x01, tipo_passo};
	return motor;
}

int Da_Passo(int estado_anterior, tipo_passo_t tipo_passo, int sentido)
{
	int novo_estado = Calcula_Novo_Estado_Motor(estado_anterior, tipo_passo, sentido);
	GPIO_PORTH_AHB_DATA_R = (GPIO_PORTH_AHB_DATA_R & ~(0x0f)) | novo_estado;
	SysTick_Wait1ms(10);
	return novo_estado;
}

int Calcula_Novo_Estado_Motor (int estado_anterior, tipo_passo_t tipo_passo, int sentido)
{
	if (tipo_passo == MEIO_PASSO && sentido > 0)
	{
		switch (estado_anterior)
		{
			case 0x01:
				return 0x03;
			case 0x03:
				return 0x02;
			case 0x02:
				return 0x06;
			case 0x06:
				return 0x04;
			case 0x04:
				return 0x0C;
			case 0x0C:
				return 0x08;
			case 0x08:
				return 0x09;
			case 0x09:
				return 0x01;
		}
	}
	else if (tipo_passo == MEIO_PASSO && sentido < 0)
	{
		switch (estado_anterior)
		{
			case 0x01:
				return 0x09;
			case 0x03:
				return 0x01;
			case 0x02:
				return 0x03;
			case 0x06:
				return 0x02;
			case 0x04:
				return 0x06;
			case 0x0C:
				return 0x04;
			case 0x08:
				return 0x0C;
			case 0x09:
				return 0x08;
		}
	}
	else if (tipo_passo == PASSO_COMPLETO && sentido > 0)
	{
		switch (estado_anterior)
		{
			case 0x01:
				return 0x02;
			case 0x02:
				return 0x04;
			case 0x04:
				return 0x08;
			case 0x08:
				return 0x01;
		}
	}
	else if (tipo_passo == PASSO_COMPLETO && sentido < 0)
	{
		switch (estado_anterior)
		{
			case 0x01:
				return 0x08;
			case 0x02:
				return 0x01;
			case 0x04:
				return 0x02;
			case 0x08:
				return 0x04;
		}
	}
	else
		while(1) {;}
	return 0;
}

void Move_Motor_Passo (int pos_motor_desejada, motor_passo_t* motor, int sentido)
{
	while (motor->pos_atual != pos_motor_desejada)
	{
		motor->estado = Da_Passo(motor->estado, motor->tipo_passo, sentido);
		motor->pos_atual += sentido;
		if (motor->pos_atual == motor->n_passos)
			motor->pos_atual = 0;
		else if (motor->pos_atual < 0)
			motor->pos_atual = motor->n_passos - 1;
	}
}

#endif
