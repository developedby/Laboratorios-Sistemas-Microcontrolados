// Biblioteca para mover motor de passo com a PAT DAELN e Tiva C TM4C129
// Nicolas Abril e Lucca Rawlyk

typedef enum tipo_passo {PASSO_COMPLETO, MEIO_PASSO} tipo_passo_t;

int Da_Passo(int estado_anterior, tipo_passo_t tipo_passo)
{
	int novo_estado = estado_anterior;
	
	if (tipo_passo == MEIO_PASSO)
	{
		if (estado_anterior % 3)
		{
			
		}
	}
	else if (tipo_passo == PASSO_COMPLETO)
	{
		novo_estado <<= 1;
		if (novo_estado > 1<<3)
		{
			novo_estado = 1;
		}
	}

	return novo_estado;
}