; Representação do sinal:
;	São usadas as duas portas de saída PORTB e PORTD.
;
;		São 5 semáforos ao total, sendo 4 semáforos com 3 estados (verde, amarelo e vermelho) 
;		e 1 semáforo com 2 estados (verde e vermelho).
;
;		Cada estado de cada semáforo é representado por um bit. 
;		
;		Para semáforos de 3 estados:
;			001 --> Vermelho
;			010 --> Amarelo
;			100 --> Verde
;		Para o semáforo de 2 estados:
;			01 --> Vermelho
;			10 --> Verde
;      
;		PORTB:
;			00|000|000
;			^   ^   ^
;      Pedestre |   |_ Semáforo 1
;               |__ Semáforo 2
;
;		PORTD:
;           00|000|000
;				^   ^
;  Semáforo 4___|   |_ Semáforo 3
;
jmp reset
.org OC1Aaddr
jmp OC1A_Interrupt

.def temp = r16
.def leds = r17 ;current LED value
.cseg

#define CLOCK 16.0e6 ;clock speed
#define BASE 10.0e-6

clock_set:
	; Essa função é responsável por redefinir o tempo a ser contado pelo timer

	push r16
	in r16, SREG
	push r16

	.equ PRESCALE = 0b101
	.equ PRESCALE_DIV = 1024
	.equ WGM = 0b0100 

	.equ TOP = int(0.5 + ((CLOCK/PRESCALE_DIV)*DELAY))
	.if TOP > 65535
	.error "TOP is out of range"
	.endif
	
	ldi temp, high(TOP) 
	sts OCR1AH, temp
	ldi temp, low(TOP)
	sts OCR1AL, temp
	ldi temp, ((WGM&0b11) << WGM10) 
	sts TCCR1A, temp
	ldi temp, ((WGM>> 2) << WGM12)|(PRESCALE << CS10)
	sts TCCR1B, temp

	pop r16
	out SREG,r16
	pop r16
	ret

OC1A_Interrupt:
	; Trata a interrupção do timer
	
	push r16
	in r16, SREG
	push r16


	call clock_set
	cpi stateFlag,7
	breq state7
	subi stateFlag,-1
	state7:
		subi stateFlag,6

	pop r16
	out SREG,r16
	pop r16
	reti ; retorno da interrupção

reset:
	.cseg
	.def stateFlag = r25 ; Guarda o número do estado atual
	ldi stateFlag, 0b00000001 ; Definindo que estamos no primeiro estado.
	
	;Inicialização da pilha
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
	
	; Configuração para utilizar as portas B e D como saída
	ldi temp, $FF
	out DDRB, temp
	out DDRD, temp

	; Habilitar flag de interrupção global
	lds temp, TIMSK1
	sbr temp, 1 << OCIE1A
	sts TIMSK1, temp
	sei

	loop:
		; Switch case para verificação do próximo estado a ser exibido no sinal.
		cpi stateFlag, 1
		breq case1
		cpi stateFlag, 2
		breq case2
		cpi stateFlag, 3
		breq case3
		cpi stateFlag, 4
		breq case4
		cpi stateFlag, 5
		breq case5
		cpi stateFlag, 6
		breq case6
		cpi stateFlag, 7
		breq case7

	
		case1:
			call Estado1
			rjmp end_switch
		case2:
			call Estado2
			rjmp end_switch
		case3:
			call Estado3
			rjmp end_switch
		case4:
			call Estado4
			rjmp end_switch
		case5:
			call Estado5
			rjmp end_switch
		case6:
			call Estado6
			rjmp end_switch
		case7:
			call Estado7
		end_switch:
		
		rjmp loop

Estado1:
	; Função para configurar os leds do estado 1 e definição do tempo de duração até o próximo estado
	; Comportamento semelhante para os próximos estados.
		
	push r16
	in r16, SREG
	push r16
	
	ldi leds, 0b01100001; pedestre fechado, semáforo 2 verde, semáforo 1 vermelho
	out PORTB, leds
	ldi leds, 0b00001100; semáforo 4 vermelho,semáforo 3 verde
	out PORTD, leds
	.set delay = 27.0*BASE ; Tempo para o próximo estado

	pop r16
	out SREG,r16
	pop r16


Estado2:
	
	push r16
	in r16, SREG
	push r16

	ldi leds, 0b01010001 ; pedestre fechado, semáforo 2 amarelo, semáforo 1 vermelho 
	out PORTB, leds 
	ldi leds, 0b00001100 ; semáforo 4 vermelho,semáforo 3 verde
	out PORTD, leds
	.set delay = 3.0*BASE

	pop r16
	out SREG,r16
	pop r16

	ret

Estado3:

	push r16
	in r16, SREG
	push r16

	ldi leds, 0b01001001 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 vermelho 
	out PORTB, leds 
	ldi leds, 0b00100100 ; semáforo 4 verde,semáforo 3 verde
	out PORTD, leds 
	.set delay = 57.0*BASE

	pop r16
	out SREG,r16
	pop r16

	ret

Estado4:

	push r16
	in r16, SREG
	push r16

	ldi leds, 0b01001001 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 vermelho 
	out PORTB, leds 
	ldi leds, 0b00010010 ; semáforo 4 amarelo,semáforo 3 amarelo
	out PORTD, leds
	.set delay = 3.0*BASE

	pop r16
	out SREG,r16
	pop r16

	ret

Estado5:
	
	push r16
	in r16, SREG
	push r16

	ldi leds, 0b10001001 ; pedestre aberto, semáforo 2 vermelho, semáforo 1 vermelho 
	out PORTB, leds 
	ldi leds, 0b00001001 ; semáforo 4 vermelho,semáforo 3 vermelho
	out PORTD, leds
	.set delay = 10*BASE

	pop r16
	out SREG,r16
	pop r16

	ret

Estado6:

	push r16
	in r16, SREG
	push r16

	ldi leds, 0b01001100 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 verde 
	out PORTB, leds 
	ldi leds, 0b00001001 ; semáforo 4 vermelho,semáforo 3 vermelho
	out PORTD, leds
	.set delay = 18*BASE

	pop r16
	out SREG,r16
	pop r16

	ret

Estado7:

	push r16
	in r16, SREG
	push r16

	ldi leds, 0b01001010 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 amarelo 
	out PORTB, leds 
	ldi leds, 0b00001001 ; semáforo 4 vermelho,semáforo 3 vermelho
	out PORTD, leds
	.set delay = 3*BASE

	pop r16
	out SREG,r16
	pop r16

	ret