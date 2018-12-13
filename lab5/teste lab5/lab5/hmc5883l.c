// Biblioteca para uso do HMC5883L com a PAT DAELN e Tiva C TM4C129
// Nicolas Abril e Lucca Rawlyk

#include <stdint.h>
#include "tm4c1294ncpdt.h"

#define MAXRETRIES 5 // number of receive attempts before giving up

void SysTick_Wait1ms (uint32_t delay_ms);

void I2C0_Init (void);
void I2C_Set_Slave_Address (uint32_t slaveAddress);
void I2C_End_Transmission (void);
uint32_t I2C_Send_Middle (uint32_t data1);
uint32_t I2C_Send_Start ( uint32_t data1);
int I2C_Read (uint32_t reg_addr, int n_bytes, uint8_t* buffer);

void I2C0_Init(void)
{
	SYSCTL_RCGCI2C_R |= 0x0001; // activate I2C0
	SYSCTL_RCGCGPIO_R |= 0x0002; // activate port B
	while((SYSCTL_PRGPIO_R&0x0002) == 0){};// ready?

	GPIO_PORTB_AHB_AFSEL_R |= 0x0C; // 3) enable alt funct on PB2,3
	GPIO_PORTB_AHB_ODR_R |= 0x08; // 4) enable open drain on PB3 only
	GPIO_PORTB_AHB_DEN_R |= 0x0C; // 5) enable digital I/O on PB2,3
	// 6) configure PB2,3 as I2C
	GPIO_PORTB_AHB_PCTL_R = (GPIO_PORTB_AHB_PCTL_R&0xFFFF00FF)+0x00002200;
	GPIO_PORTB_AHB_AMSEL_R &= ~0x0C; // 7) disable analog functionality on PB2,3
	I2C0_MCR_R = I2C_MCR_MFE; // 9) master function enable
	I2C0_MTPR_R &= ~I2C_MTPR_TPR_M;
	I2C0_MTPR_R |= 0x27; // 8) configure for 100 kbps clock
}

void I2C_Set_Slave_Address (uint32_t slaveAddress)
{
I2C0_MSA_R = ((slaveAddress) << 1);
}

void I2C_End_Transmission (void)
{
	// Espera poder enviar
	while(I2C0_MCS_R&(I2C_MCS_BUSY))
		;
	I2C0_MCS_R = I2C_MCS_STOP;
	while(I2C0_MCS_R&(I2C_MCS_BUSY) || !(I2C0_MCS_R&I2C_MCS_IDLE))
		;
}

uint32_t I2C_Send_Middle (uint32_t data1)
{
	// Espera poder enviar
	while(I2C0_MCS_R&(I2C_MCS_BUSY))
		;
	I2C0_MSA_R &= ~I2C_MSA_RS; // MSA[0] is 0 for send
	I2C0_MDR_R = (I2C0_MDR_R&~I2C0_MDR_R) | (data1&I2C_MDR_DATA_M); // prepare first byte
	I2C0_MCS_R = I2C_MCS_RUN; // master enable
	SysTick_Wait1ms(1);
	// Espera poder enviar
	while(I2C0_MCS_R&(I2C_MCS_BUSY))
		;
	return (I2C0_MCS_R&(I2C_MCS_DATACK|I2C_MCS_ADRACK|I2C_MCS_ERROR));
}


uint32_t I2C_Send_Start (uint32_t data1)
{
	// Espera poder enviar
	while(I2C0_MCS_R&(I2C_MCS_BUSY|I2C_MCS_BUSBSY) && !(I2C0_MCS_R&I2C_MCS_IDLE))
		;
	I2C0_MSA_R &= ~I2C_MSA_RS; // MSA[0] is 0 for send
	I2C0_MDR_R = (I2C0_MDR_R&~I2C_MDR_DATA_M) | (data1&I2C_MDR_DATA_M); // prepare first byte
	I2C0_MCS_R = I2C_MCS_START | I2C_MCS_RUN;
	SysTick_Wait1ms(1);
	// Espera poder enviar
	while(I2C0_MCS_R&(I2C_MCS_BUSY))
		;
	// return error bits
	return (I2C0_MCS_R&(I2C_MCS_DATACK|I2C_MCS_ADRACK|I2C_MCS_ERROR));
}

int I2C_Read(uint32_t reg_addr, int n_bytes, uint8_t* buffer)
{
	// Espera poder enviar
	while(I2C0_MCS_R&(I2C_MCS_BUSY|I2C_MCS_BUSBSY) && !(I2C0_MCS_R&I2C_MCS_IDLE))
		;
	//I2C0_MSA_R &= ~I2C_MSA_RS;
	I2C0_MDR_R = (I2C0_MDR_R & ~I2C_MDR_DATA_M)	| reg_addr;
	//I2C0_MCS_R = I2C_MCS_START | I2C_MCS_RUN;
	
	//while(I2C0_MCS_R&(I2C_MCS_BUSY))
	//	;
	
	I2C0_MSA_R |= I2C_MSA_RS;

	for (int i = 0; i < n_bytes; i++)
	{
		if(i == 0)
			I2C0_MCS_R = I2C_MCS_ACK | I2C_MCS_START | I2C_MCS_RUN;
		else if (i > 0 && i < n_bytes-1)
				I2C0_MCS_R = I2C_MCS_ACK | I2C_MCS_RUN;
		else
					I2C0_MCS_R = I2C_MCS_STOP | I2C_MCS_RUN;
		
		while(I2C0_MCS_R&(I2C_MCS_BUSY))
			;
		
		buffer[i] = I2C0_MDR_R & I2C_MDR_DATA_M;
		SysTick_Wait1ms(5);
	}
	return 0;
}
