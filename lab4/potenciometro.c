// Biblioteca para leitura do potenciômetro da DAT DAELN usando o TM4C1294
// Nicolas Abril e Lucca Rawlyk

#include <stdint.h>
#include <stdlib.h>
#include "tm4c1294ncpdt.h"

void Init_Potenciometro (void);
int Le_Potenciometro (void);