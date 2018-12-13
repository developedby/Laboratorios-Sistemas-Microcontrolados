#include "tm4c1294ncpdt.h"
#include <stdint.h>
#include <stdio.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

void PLL_Init(void);
void SysTick_Init(void);
void SysTick_Wait1ms (uint32_t delay_ms);
void Display_Clean (void);
void Display_Print (const char* mensagem, int linha, int coluna);
void Display_Erro (void);
void Init_Display (void);
void Display_Send_Data (int byte);
void Display_Send_Instruction (int byte);

void I2C0_Init(void);
void I2C_Set_Slave_Address (uint32_t slaveAddress);
void I2C_End_Transmission (void);
uint32_t I2C_Send_Middle (uint32_t data1);
uint32_t I2C_Send_Start ( uint32_t data1);
int I2C_Read(uint32_t reg_addr, int n_bytes, uint8_t* buffer);
void Swap_Bytes (uint8_t *num);

int main (void){
	PLL_Init();
	SysTick_Init();
	Init_Display();
	I2C0_Init();
	I2C_Set_Slave_Address(0x1E); // Slave Address is 0x1E according to HMC5883L datasheet

	//initialization process for “continuous-measurement mode (HMC5883L) Page 18

	//(8-average, 15 Hz default, normal measurement)
	I2C_Send_Start (0x00);
	I2C_Send_Middle (0x70);
	I2C_End_Transmission();

	//(Gain=5, or any other desired gain)
	I2C_Send_Start (0x01);
	I2C_Send_Middle (0xA0);
	I2C_End_Transmission();

	//(Continuous-measurement mode)
	I2C_Send_Start (0x02);
	I2C_Send_Middle (0x00);
	I2C_End_Transmission();

	//Delay
	SysTick_Wait1ms(6);

	char mag_field_ascii[3][10];
	unsigned char mag_field_bytes [6];
	char degree_xy_ascii[10];
	float degree_xy;
	int deg_xi, deg_yi;
	float deg_x, deg_y;
	while (1)
	{			
		I2C_Read(0x06, 6, mag_field_bytes);
		I2C_Send_Start(0x03);
		I2C_End_Transmission();
		SysTick_Wait1ms(67);
		
		//Swap_Bytes(&(mag_field_bytes[0]));
		//Swap_Bytes(&(mag_field_bytes[2]));
		//Swap_Bytes(&(mag_field_bytes[4]));
		
		sprintf(mag_field_ascii[0], "%d", ((int16_t*)mag_field_bytes)[0]);
		sprintf(mag_field_ascii[1], "%d", ((int16_t*)mag_field_bytes)[1]);
		sprintf(mag_field_ascii[2], "%d", ((int16_t*)mag_field_bytes)[2]);
		
		Display_Clean();
		Display_Print("x:", 1, 1);
		Display_Print(mag_field_ascii[0], 1, 3);
		Display_Print("y:", 1, 8);
		Display_Print(mag_field_ascii[2], 1, 10);
		Display_Print("z:", 2, 1);
		Display_Print(mag_field_ascii[1], 2, 3);
		
		deg_xi = ((int16_t*)mag_field_bytes)[0];
		deg_yi = ((int16_t*)mag_field_bytes)[2];
		deg_x = (float)(deg_xi);
		deg_y = (float)(deg_yi);
		degree_xy = atan2(deg_y, deg_x);
		degree_xy *= M_PI/180.0;
		sprintf(degree_xy_ascii, "%d", (int)degree_xy);
		
		Display_Print("ang:", 2, 8);
		Display_Print(degree_xy_ascii, 2, 12);
		
		SysTick_Wait1ms(300);
	}
}

void Swap_Bytes (uint8_t *num)
{
	uint8_t swapper = num[0];
	num[0] = num[1];
	num[1] = swapper;
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
