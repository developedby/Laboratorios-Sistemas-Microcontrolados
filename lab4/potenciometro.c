// Biblioteca para leitura do potenciômetro da DAT DAELN usando o TM4C1294
// Nicolas Abril e Lucca Rawlyk

#include <stdint.h>
#include <stdlib.h>
#include "tm4c1294ncpdt.h"

void Init_Potenciometro (void);
int Le_Potenciometro (void);

#define POT_PIN 4

void Init_Potenciometro (void)
{
// Liga o pino
	//1a. Ativar o clock para a porta setando o bit correspondente no registrador RCGCGPIO
	SYSCTL_RCGCGPIO_R |= SYSCTL_PPGPIO_P4;
	//1b.   após isso verificar no PRGPIO se a porta está pronta para uso.
  while((SYSCTL_PRGPIO_R & (SYSCTL_PPGPIO_P4 )) != SYSCTL_PPGPIO_P4){};
	
	// 2. Setar o AMSEL para habilitar a analógica
	GPIO_PORTE_AHB_AMSEL_R |= 1<<POT_PIN;
		
	// 3. Limpar PCTL para selecionar o GPIO
	//GPIO_PORTE_AHB_PCTL_R &= ~(15<<(MOTOR_INPUT_A*4) | 1<<MOTOR_INPUT_B);

	// 4. DIR para 0 se for entrada, 1 se for saída
	GPIO_PORTE_AHB_DIR_R &= ~(1<<POT_PIN);
		
	// 5. Limpar os bits AFSEL para 0 para selecionar GPIO sem função alternativa	
	GPIO_PORTE_AHB_AFSEL_R |= 1<<POT_PIN;
		
	// 6. Setar os bits de DEN para habilitar I/O digital	
	GPIO_PORTE_AHB_DEN_R &= ~(1<<POT_PIN);
		
// Liga o ADC
	SYSCTL_RCGCADC_R = SYSCTL_RCGCADC_R0;
	while((SYSCTL_PRADC_R & (SYSCTL_PRADC_R0 )) != SYSCTL_PRADC_R0)
		;
		
	ADC0_PC_R &= ~ADC_PC_MCR_M;
	ADC0_PC_R |= ADC_PC_MCR_FULL;
	ADC0_SSPRI_R = (ADC0_SSPRI_R & ~ADC_SSPRI_SS0_M) | 3;
	ADC0_SSPRI_R = (ADC0_SSPRI_R & ~ADC_SSPRI_SS0_M) | 2;
	ADC0_SSPRI_R = (ADC0_SSPRI_R & ~ADC_SSPRI_SS0_M) | 1;
	ADC0_SSPRI_R = (ADC0_SSPRI_R & ~ADC_SSPRI_SS0_M) | 0;
		
	ADC0_ACTSS_R &= ~ADC_ACTSS_ASEN3;
	
	ADC0_EMUX_R = (ADC0_EMUX_R & ~ADC_EMUX_EM3_M) | ADC_EMUX_EM3_PROCESSOR;
	
	ADC0_SSMUX3_R =  (ADC0_SSMUX3_R & ~ADC_SSMUX3_MUX0_M) | (9<<ADC_SSMUX3_MUX0_S);
	
	ADC0_SSCTL3_R |= ADC_SSCTL3_IE0 | ADC_SSCTL3_END0; 
	
	ADC0_ACTSS_R |= ADC_ACTSS_ASEN3;
}

int Le_Potenciometro (void)
{

	ADC0_PSSI_R |= ADC_PSSI_SS3;
	while (!(ADC0_RIS_R & ADC_RIS_INR3))
		;
	
	int sample = (ADC0_SSFIFO3_R & ADC_SSFIFO3_DATA_M) >> ADC_SSFIFO3_DATA_S;
	
	ADC0_ISC_R |= ADC_ISC_IN3;
	
	ADC0_RIS_R &= ~ADC_RIS_INR3;
	
	return sample;
}
