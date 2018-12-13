#include "tm4c1294ncpdt.h"
#include <stdint.h>
#include <stdio.h>

//Global Variables
int i=0;
uint32_t DATA;

void PLL_Init(void);
void SysTick_Init(void);
void SysTick_Wait1ms (uint32_t delay_ms);
void Display_Clean (void);
void Display_Print (const char* mensagem, int linha, int coluna);
void Display_Erro (void);
void Init_Display (void);
void Display_Send_Data (int byte);
void Display_Send_Instruction (int byte);

#define I2C_MCS_ACK 0x00000008 // Data Acknowledge Enable
#define I2C_MCS_DATACK 0x00000008 // Acknowledge Data
#define I2C_MCS_ADRACK 0x00000004 // Acknowledge Address
#define I2C_MCS_STOP 0x00000004 // Generate STOP
#define I2C_MCS_START 0x00000002 // Generate START
#define I2C_MCS_ERROR 0x00000002 // Error
#define I2C_MCS_RUN 0x00000001 // I2C Master Enable
#define I2C_MCS_BUSY 0x00000001 // I2C Busy
#define I2C_MCR_MFE 0x00000010 // I2C Master Function Enable

#define MAXRETRIES 5 // number of receive attempts before giving up

void I2C0_Init(void){
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
	// 16MHZ*(TPR+1)*20ns => TPR=7
}

void Slave_Address (uint32_t slaveAddress){

I2C0_MSA_R = ((slaveAddress) << 1);

}

void I2C_End_Transmission (void){
	while(I2C0_MCS_R&I2C_MCS_BUSY){};// wait for I2C ready
	//I2C0_MSA_R &= ~0x01; // MSA[0] is 0 for send
	// I2C0_MDR_R = data1&0xFF; // prepare first byte
	I2C0_MCS_R = (0
	// & ~I2C_MCS_ACK // no data ack (no data on send)
	| I2C_MCS_STOP // generate stop
	// | I2C_MCS_START // no start/restart
	| I2C_MCS_RUN); // master enable
	while(I2C0_MCS_R&I2C_MCS_BUSY){};// wait for transmission done

}

uint32_t I2C_Send_Middle (uint32_t data1){
	while(I2C0_MCS_R&I2C_MCS_BUSY){};// wait for I2C ready
	I2C0_MSA_R &= ~0x01; // MSA[0] is 0 for send
	I2C0_MDR_R = data1&0xFF; // prepare first byte
	I2C0_MCS_R = (0
	// & ~I2C_MCS_ACK // no data ack (no data on send)
	// | I2C_MCS_STOP // no stop
	// | I2C_MCS_START // no start/restart
	| I2C_MCS_RUN); // master enable
	SysTick_Wait1ms(1);
	while(I2C0_MCS_R&I2C_MCS_BUSY){};// wait for transmission done
	// return error bits
	return (I2C0_MCS_R&(I2C_MCS_DATACK|I2C_MCS_ADRACK|I2C_MCS_ERROR));
}


uint32_t I2C_Send_Start ( uint32_t data1){
	while(I2C0_MCS_R&I2C_MCS_BUSY){};// wait for I2C ready
	I2C0_MSA_R &= ~0x01; // MSA[0] is 0 for send
	I2C0_MDR_R = data1&0xFF; // prepare first byte
	I2C0_MCS_R = (0
	// & ~I2C_MCS_ACK // no data ack (no data on send)
	// | I2C_MCS_STOP // generate stop
	| I2C_MCS_START // generate start/restart
	| I2C_MCS_RUN); // master enable
		SysTick_Wait1ms(1);
	while(I2C0_MCS_R&I2C_MCS_BUSY){};// wait for transmission done
	// return error bits
	return (I2C0_MCS_R&(I2C_MCS_DATACK|I2C_MCS_ADRACK|I2C_MCS_ERROR));
}

uint32_t I2C_Read(uint32_t slave, int n_bytes){
	int retryCounter = 1;
	do{
		while(I2C0_MCS_R&I2C_MCS_BUSY){};// wait for I2C ready
		I2C0_MSA_R = (slave<<1)&0xFE; // MSA[7:1] is slave address
		I2C0_MSA_R |= 0x01; // MSA[0] is 1 for receive
		I2C0_MCS_R = (0
		// & ~I2C_MCS_ACK // negative data ack (last byte)
		| I2C_MCS_STOP // generate stop
		| I2C_MCS_START // generate start/restart
		| I2C_MCS_RUN); // master enable
		while(I2C0_MCS_R&I2C_MCS_BUSY){};// wait for transmission done
		retryCounter = retryCounter + 1; // increment retry counter
	} // repeat if error
	while(((I2C0_MCS_R&(I2C_MCS_ADRACK|I2C_MCS_ERROR)) != 0) && (retryCounter <= MAXRETRIES));
	return (I2C0_MDR_R&0xFF); // usually returns 0xFF on error
	}


void SystemInit (void){}

int main (void){
	PLL_Init();
	SysTick_Init();
	Init_Display();
	I2C0_Init();
	Slave_Address (0x1E); // Slave Address is 0x1E according to HMC5883L datasheet

	//initialization process for “continuous-measurement mode (HMC5883L) Page 18

	//(8-average, 15 Hz default, normal measurement)
	//I2C_Send_Start (0x3C);
	I2C_Send_Middle (0x00);
	I2C_Send_Middle (0x70);

	//(Gain=5, or any other desired gain)
	//I2C_Send_Start (0x3C);
	I2C_Send_Middle (0x01);
	I2C_Send_Middle (0xA0);

	//(Continuous-measurement mode)
	//I2C_Send_Start (0x3C);
	I2C_Send_Middle (0x02);
	I2C_Send_Middle (0x00);

	//Delay
	SysTick_Wait1ms(6);

	// End Transmission
	I2C_End_Transmission ();

	char printer[10];
	while (1){
		//I2C_Send_Start (0x3D);	// I2C Address to Read Data according to HMC5883L datasheet page 2
		I2C_Send_Start (0x03);	// Address location 03 which is X-MSB
		I2C_End_Transmission();
		
		DATA = I2C_Read(0x1E, 6);	//Reading X-MSB
		sprintf(printer, "%d", DATA);
		Display_Print(printer, 1, 1);
	}

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
