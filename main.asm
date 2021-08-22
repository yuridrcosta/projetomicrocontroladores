;Equipe: Victor Mafra, Yuri Dimitri e André dos Santos 
;
;Representação do sinal:
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

.def temp = r16
.def leds = r17 ; Usado para definir a configuração dos leds
.def timeCount = r18 ; Conta quantas interrupções faltam pro próximo estado
.def actualState = r20 ; Registra em qual estado está

.cseg

jmp reset
.org OC1Aaddr
jmp OCI1A_Interrupt

OCI1A_Interrupt:
	; A cada interrupção, diminui 1ms do tempo que falta pro próximo estado

	push r16
	in r16, SREG
	push r16
	
	subi timeCount, 1

	pop r16
	out SREG, r16
	pop r16
	reti

reset:
	ldi timeCount, 0 ;timeCount = 0 para setar o primeiro estado
	ldi actualState, 1 ; começo no estado 1

	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	;setando os pinos da porta B

	ldi temp, $FF
	out DDRB, temp

	;setando os pinos da porta D
	ldi temp, $3F
	out DDRD, temp

	#define CLOCK 16.0e6 ;clock do arduino laboratório
	#define DELAY 0.001  ;delay = 1ms para contar de 1ms em 1ms

	.equ PRESCALE = 0b100
	.equ PRESCALE_DIV = 256
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
	lds r16, TIMSK1
	sbr r16, 1 <<OCIE1A
	sts TIMSK1, r16

	sei

	;loop principal

	lp: cpi timeCount, 0 ; timeCount == 0 indica que chegou a hora de mudar de estado.
		brne lp 

		s1:	cpi actualState, 1 ; Verifica se o próximo estado é o estado 1
			brne s2

			ldi leds, 0b01100001 ; pedestre fechado, semáforo 2 verde, semáforo 1 vermelho 
			out PORTB, leds
			ldi leds, 0b00001100 ; semáforo 4 vermelho,semáforo 3 verde
			out PORTD, leds
				
			ldi timeCount, 27 ;#segundos do estado 1 para o estado 2
			inc actualState	  ;actualState = actualState + 1 -> estado 2
			rjmp lp		  ;timer contando até 27 ms
			
		s2:	cpi actualState, 2 ;este é o estado 2?
			brne s3
				
			ldi leds, 0b01010001 ; pedestre fechado, semáforo 2 amarelo, semáforo 1 vermelho 
			out PORTB, leds 
			ldi leds, 0b00001100 ; semáforo 4 vermelho,semáforo 3 verde
			out PORTD, leds
					
			ldi timeCount, 3 ; #segundos do estado 2 para o estado 3
			inc actualState    ;estado = estado + 1 -> estado 3
			rjmp lp

		s3:	cpi actualState, 3 ;estamos no estado 3?
			brne s4
				
			ldi leds, 0b01001001 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 vermelho 
			out PORTB, leds 
			ldi leds, 0b00100100 ; semáforo 4 verde,semáforo 3 verde
			out PORTD, leds

				
			ldi timeCount, 57 ; #segundos do estado 3 para o estado 4
			inc actualState     ;estado = estado + 1 -> estado 4
			rjmp lp

		s4:	cpi actualState, 4; este é o estado 4?
			brne s5
				
			ldi leds, 0b01001001 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 vermelho 
			out PORTB, leds 
			ldi leds, 0b00010010 ; semáforo 4 amarelo,semáforo 3 amarelo
			out PORTD, leds

			ldi timeCount, 3 ; #segundos do estado 4 para o estado 5
			inc actualState    ;estado = estado + 1 -> estado 5
			rjmp lp

		s5:	cpi actualState, 5 ; este é o estado 5?
			brne s6
				
			ldi leds, 0b10001001 ; pedestre aberto, semáforo 2 vermelho, semáforo 1 vermelho 
			out PORTB, leds 
			ldi leds, 0b00001001 ; semáforo 4 vermelho,semáforo 3 vermelho
			out PORTD, leds

			ldi timeCount, 10 ; #segundos do estado 5 para o estado 6
			inc actualState	  ;estado = estado + 1 -> estado 6
			rjmp lp

		s6:	cpi actualState, 6
			brne s7
				
			ldi leds, 0b01001100 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 verde 
			out PORTB, leds 
			ldi leds, 0b00001001 ; semáforo 4 vermelho,semáforo 3 vermelho
			out PORTD, leds

			ldi timeCount, 18 ; #segundos do estado 6 para o estado 7
			inc actualState     ;estado = estado + 1 -> estado 7
			rjmp lp


		s7:	cpi actualState, 7
			brne lp
				
			ldi leds, 0b01001010 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 amarelo	 
			out PORTB, leds 
			ldi leds, 0b00001001 ; semáforo 4 vermelho,semáforo 3 vermelho
			out PORTD, leds

			ldi timeCount, 3 ; #segundos do estado 7 para o estado 1
			ldi actualState, 1 ;retorno ao estado 1
			rjmp lp
