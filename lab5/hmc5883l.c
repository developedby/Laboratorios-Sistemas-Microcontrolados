// Biblioteca para uso do HMC5883L com a PAT DAELN e Tiva C TM4C129
// Nicolas Abril e Lucca Rawlyk

#include <stdint.h>
#include "tm4c1294ncpdt.h"

void SysTick_Wait1ms (uint32_t delay_ms);

void Init_Magnetometro (void);
void Calibra_Magnetometro (void);
void Le_Magnetometro (void);

void Init_Magnetometro (void)
{
	//1a. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO
	//1b.   após isso verificar no PRGPIO se a porta está pronta para uso.
  SYSCTL_RCGCGPIO_R |= SYSCTL_RCGCGPIO_R1;  
    while((SYSCTL_PRGPIO_R & (SYSCTL_RCGCGPIO_R1) ) != (SYSCTL_RCGCGPIO_R1) ){};
        
   	// 2. Desabilitar a funcionalidade analógica dos pinos do GPIO no registrador GPIOAMSEL.
	GPIO_PORTB_AHB_AMSEL_R = 0x00;

	// 3. Preencher a função alternativa dos pinos do GPIO, para o SCL e SDA, no registrador
	// GPIOPCTL (verificar a tabela 10-2 no datasheet páginas 743-746)
	//COLOCAR 0010 NO TERCEIRO BLOCO (PB2) E 0010 NO QUARTO BLOCO (PB3) CONFORME TABELA E PAG 788
    GPIO_PORTB_AHB_PCTL_R = 0x2200;
	
	// 4. Habilitar os bits de função alternativa no registrador GPIOAFSEL para o pino do GPIO.
    GPIO_PORTB_AHB_AFSEL_R = 0xC;
	
	// 5. Habilitar a função digital no pino do GPIO no registrador GPIODEN
	GPIO_PORTB_AHB_DEN_R = 0xC;
	
	// 6. Setar o pino que será I2CSDA para dreno aberto no registrador GPIOODR
	GPIO_PORTB_AHB_ODR_R = 0x8;
    
	SYSCTL_RCGCI2C_R |= 0x1;
	while((SYSCTL_PRI2C_R  & (0x1) ) != (0x1) ){};
	
	// 8. Habilitar a função de master no registrador I2CMCR escrevendo 1 no bit MFE.
	I2C0_MCR_R = 0x10;

    // 9. Configurar o clock no campo TPR registrador I2CMTPR.
	I2C0_MTPR_R = 0x27;
}	


int Send_I2C (char address, char* data, int n_bytes)
{
	SysTick_Wait1ms(1);
  // espera o I2C ficar pronto, checa o flag de busy
  while(I2C0_MCS_R&0x01){};
  
  I2C0_MSA_R = address << 1;    // MSA[7:1] endereço do slave 
  I2C0_MSA_R &= ~(0x01);   // MSA[0] 1 para leitura
  I2C0_MDR_R = data[0];	  //endereço do data pointer
  I2C0_MCS_R = (0 | 0x02 | 0x01); 

	SysTick_Wait1ms(1); 
	while(I2C0_MCS_R & 0x01) {}; // espera a transmissão concluir
	//Verifica se tem erro 				
	if ((I2C0_MCS_R & 0x02) != 0)
	{
		SysTick_Wait1ms(1);
		I2C0_MCS_R = 0x04;
		return 0xFF; //error
	}
		
	for(int i = 1; i < n_bytes; i++)
	{
		I2C0_MDR_R = data[i];
		SysTick_Wait1ms(1);
		I2C0_MCS_R = 0x01;
		
		SysTick_Wait1ms(1); 
		while(I2C0_MCS_R & 0x01) {}; // espera a transmissão concluir
		//Verifica se tem erro 				
		if ((I2C0_MCS_R & 0x02) != 0)
		{
			SysTick_Wait1ms(1);
			I2C0_MCS_R = 0x04;
			return 0xFF; //error
		}
	}
	
	I2C0_MCS_R = (0 | 0x04 | 0x01);
  // espera a transmissão concluir
  while(I2C0_MCS_R & 0x01) {};
		
	return 0;
}

int Receive_I2C (char address, char* data, int max_n_bytes)
{
	// espera o I2C ficar pronto, checa o flag de busy
	SysTick_Wait1ms(1);
  while(I2C0_MCS_R & 0x01){};
		
	// Realiza a operação de leitura
  while(I2C0_MCS_R&0x01){};// espera o I2C ficar pronto, checa o flag de busy
  I2C0_MSA_R = 0x3D << 1;    // MSA[7:1] endereço do slave 
  I2C0_MSA_R |= 0x01;   // MSA[0] 1 para leitura
  I2C0_MCS_R = (0 | 0x08 | 0x02 | 0x01); //gera start/restart/habilita o master
	
	SysTick_Wait1ms(1);
	while(I2C0_MCS_R & 0x01) {};// espera a transmissão concluir
	//Verifica se tem erro	
	if ((I2C0_MCS_R & 0x02) != 0)
	{
		SysTick_Wait1ms(1);
		I2C0_MCS_R = 0x04;
		return 0xFF; //error
	}
	
	for (int i = 1; i < max_n_bytes; i++)
	{
		
	}
}