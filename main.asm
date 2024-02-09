;
; AssemblerApplication6.asm
;
; Created: 4/02/2024 14:28:53
; Author : diego
;
//ENCABEZADO
.include "M328PDEF.inc"
.cseg ;definir que se va  iniciatr el segmento de código del programa
.org 0x00;en que parte del código vamos a iniciar

LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R17, HIGH(RAMEND)
OUT SPH, R17
tabla7seg: .DB 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x73, 0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47

//CONFIRGURACIÖN
SETUP: 
	LDI R16, (1 << CLKPCE) ;colocar 1 en el 7mo bit del registro CLKPR
	STS CLKPR, R16 ;mover a CLKPR
	LDI R16, 0b0000_0011 ;dividir la frecuencia del clk en 8, 16M/8 = 2M oscilaciones por segundo
	STS CLKPR, R16 ;mover a CLKPR
	CALL TIMER0
	SBI DDRB, PB5 ;definiendo pb5 como salida (led 4)
	CBI PORTB, PB5 ;colocar 0 en el pb5
	SBI DDRB, PB4 ;definiendo pb4 como salida (led 3)
	CBI PORTB, PB4 ;colocar 0 en el pb4
	SBI DDRB, PB3 ;definiendo pb3 como salida (led 2)
	CBI PORTB, PB3 ;colocar 0 en el pb3
	SBI DDRB, PB2 ;definiendo pb2 como salida (led 1)
	CBI PORTB, PB2 ;colocar 0 en el pb2
	SBI DDRB, PB1
	CBI PORTB, PB1
	//definiendo salidas del display
	SBI DDRB, PD0 ;A
	CBI PORTD, PD0
	SBI DDRB, PD1 ;B
	CBI PORTD, PD1 
	SBI DDRB, PD2 ;C
	CBI PORTD, PD2
	SBI DDRB, PD3 ;D
	CBI PORTD, PD3 
	SBI DDRB, PD4 ;E
	CBI PORTD, PD4 
	SBI DDRB, PD5 ;F
	CBI PORTD, PD5 
	SBI DDRB, PD6 ;G
	CBI PORTD, PD6 
	LDI R16, (1 << PC4)
	LDI R16, (1 << PC5);configura el pin como entrada con pull up
	OUT PORTC, R16 ;habilitar el pull up
	CBI DDRB, PC4 ;definiendo pb1 como entrada (pushbottom)
	CBI DDRB, PC5 ;definiendo pb0 como entrada
	LDI R16, 0 ;registro del timer0
	LDI R17, 0
	LDI R18, 0 ;registro donde se guarda el contador de leds
	LDI R22, 0 ;regsitro del contador 2 de los leds
	LDI R23, 0 ;regsitro del contador 2 de los leds
	LDI R19, 0 ;registro donde se guarda el contador del display
	LDI R20, 0 ;registro del delay del antirebote
	LDI R21, 126 ;mostrar el display en 0 desde el principio
	LDI R24, 0 ;registro para comparar constantes
	RJMP LOOP

TIMER0:
	LDI R16, (1 << CS02) | (1 << CS00) ;configurar el prescaler a 1024 para un reloj de 2M
	OUT TCCR0B, R16
	LDI R16, 61 ;valor de desbordamiento
	OUT TCNT0, R16
	RET

LOOP: 
	IN R17, PINC
	IN R16, TIFR0 ;leer si hay overflow en r16
	OUT PORTD, R21 ;DISPLAY
	CALL DISPLAY ;mostrar numero en display
	SBRS R17, PC4 ;Se salta si el bit es 1 
	CALL DELAY
	SBRS R17, PC4 ;despues del delay revisa si sigue en 0
	RJMP subrutina1
	SBRS R17, PC5
	CALL DELAY
	SBRS R17, PC5
	RJMP subrutina2
	CPI R16, TOV0 ;comparar la bandera de overflow este en 1
	BRNE LOOP
	LDI R16, 61 ;valor de desbordamiento
	OUT TCNT0, R16
	SBI TIFR0, TOV0 ;apagar bandera
	CALL leds
	CP R19, R22 ;compara entre contador de leds con contador de display
	BRNE LOOP ;va a la subrutina si no son iguales
	LDI R22, 0 ;reinicia el contador de segundos
	SBI PORTB, 1 ;pone en 1 el led en pb1
	CBI PORTB, 0 ;el led regresa a estar 0
	RJMP LOOP

leds: //contadsor de 1 segundos
	INC R18
	LDI R24, 10
	CPSE R18, R24 ;se salta si es igual
	RET
	LDI R18, 0
	INC R22
leds2: //reinicia el contador cuando llega a 15
	LDI R24, 15
	CPSE R22, R24
	RJMP leds3
	LDI R22, 0
leds3: //muestra el numero en leds
	MOV R23, R22
	ROR R23
	ROR R23 ;mueve los bits 2 veces a la derecha para que se vea adecuadamente
	OUT PORTB, R23
	RET

DELAY: //delay del anti rebote
	INC R20
	CPI R20, 100
	BRNE DELAY ;se salts si la instr es cpi si es igual
	LDI R20, 0
	RET

//subrutinas donde ocurrira el contador en el display 7 seg
subrutina1: ;subrutina para el pb de incremento
	INC R19
	LDI R24, 17
	CPSE R19, R24 ;reinicia r19 cuando llega a 16
	RJMP LOOP
	LDI R19, 0
	RJMP LOOP

subrutina2: ;subrutina para el pb de decremento
	DEC R19
	LDI R24, -1
	CPSE R19, R24 ;salta la inst de abajo si es igual
	RJMP LOOP
	LDI R19, 16
	RJMP LOOP

DISPLAY: ;subrutina para traducir el contador a binario del display
	LDI ZH, HIGH(tabla7seg << 1)
	LDI ZL, LOW(tabla7seg << 1)
	ADD ZL, R19
	LPM R21, Z
	RET