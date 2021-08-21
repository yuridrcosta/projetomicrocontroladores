;
; AssemblerApplication1.asm
;
; Created: 17/08/2021 22:38:48
; Author : Andre
;


.def temp = r16
.def leds = r17 
.def count = r18 ;contador de estados
.def state = r20 ;estado atual 

.cseg

jmp reset
.org OC1Aaddr
jmp OCI1A_Interrupt

OCI1A_Interrupt:
	
	push r16
	in r16, SREG
	push r16
	
	subi count, 1

	pop r16
	out SREG, r16
	pop r16
	reti

reset:
	ldi count, 0 ;count = 0 para setar o primeiro estado
	ldi state, 1 ; começo no estado 1

	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	;setando os pinos da porta B

	ldi temp, $FF
	out DDRB, temp
	ldi leds, $FF
	out PORTB, leds

	;setando os pinos da porta D
	out DDRD, temp
	ldi leds, $3F
	out PORTD, leds

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

	lp: cpi count, 0 ;tempo já expirou?
		brne lp

		s1:	cpi state, 1 ;este é o estado 1?
			brne s2

			sp: ldi leds, 0b01100001 
			out PORTB, leds
			ldi leds, 0b00001100
			out PORTD, leds
				
			ldi count, 27 ;#segundos do estado 1 para o estado 2
			inc state	  ;state = state + 1 -> estado 2
			rjmp lp		  ;timer contando até 27 ms
			
		s2:	cpi state, 2 ;este é o estado 2?
			brne s3
				
			ldi leds, 0b01010001 ; pedestre fechado, semáforo 2 amarelo, semáforo 1 vermelho 
			out PORTB, leds 
			ldi leds, 0b00001100 ; semáforo 4 vermelho,semáforo 3 verde
			out PORTD, leds
					
			ldi count, 3 ; #segundos do estado 2 para o estado 3
			inc state    ;estado = estado + 1 -> estado 3
			rjmp lp

		s3:	cpi state, 3 ;estamos no estado 3?
			brne s4
				
			ldi leds, 0b01001001 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 vermelho 
			out PORTB, leds 
			ldi leds, 0b00100100 ; semáforo 4 verde,semáforo 3 verde
			out PORTD, leds

				
			ldi count, 57 ; #segundos do estado 3 para o estado 4
			inc state     ;estado = estado + 1 -> estado 4
			rjmp lp

		s4:	cpi state, 4; este é o estado 4?
			brne s5
				
			ldi leds, 0b01001001 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 vermelho 
			out PORTB, leds 
			ldi leds, 0b00010010 ; semáforo 4 amarelo,semáforo 3 amarelo
			out PORTD, leds

			ldi count, 3 ; #segundos do estado 4 para o estado 5
			inc state    ;estado = estado + 1 -> estado 5
			rjmp lp

		s5:	cpi state, 5 ; este é o estado 5?
			brne s6
				
			ldi leds, 0b10001001 ; pedestre aberto, semáforo 2 vermelho, semáforo 1 vermelho 
			out PORTB, leds 
			ldi leds, 0b00001001 ; semáforo 4 vermelho,semáforo 3 vermelho
			out PORTD, leds

			ldi count, 10 ; #segundos do estado 5 para o estado 6
			inc state	  ;estado = estado + 1 -> estado 6
			rjmp lp

		s6:	cpi state, 6
			brne s7
				
			ldi leds, 0b01001100 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 verde 
			out PORTB, leds 
			ldi leds, 0b00001001 ; semáforo 4 vermelho,semáforo 3 vermelho
			out PORTD, leds

			ldi count, 18 ; #segundos do estado 6 para o estado 7
			inc state     ;estado = estado + 1 -> estado 7
			rjmp lp


		s7:	cpi state, 7
			brne lp
				
			ldi leds, 0b01001010 ; pedestre fechado, semáforo 2 vermelho, semáforo 1 amarelo	 
			out PORTB, leds 
			ldi leds, 0b00001001 ; semáforo 4 vermelho,semáforo 3 vermelho
			out PORTD, leds

			ldi count, 3 ; #segundos do estado 7 para o estado 1
			ldi state, 1 ;retorno ao estado 1
			rjmp lp