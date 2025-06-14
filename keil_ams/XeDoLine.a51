; Xe do line su dung cam bien hong ngoai
;
;Written by: HUYNH DANG KHOA	11:11PM		08/06/2022
;=====================================================

;---------------------------
;LCD
BUS_LCD			EQU		P0
EN				BIT		P3.6
RS				BIT		P3.7
;---------------------------

FLAG0			BIT		00H				;PWM, =1 THI PWM KHI DANG MUC 1, =0 KHI PWM DANG MUC 0
FLAG1			BIT		01H	   			;MOTOR TRAI
FLAG2			BIT		02H				;MOTOR PHAI
FLAG3			BIT		03H				;CO IN/OUT
FLAG4			BIT		04H				;CO LEFT/RIGHT
FLAG5			BIT		05H				;PREVIOUS STATE CUA FLAG3
FLAG6			BIT		06H				;
FLAG7			BIT		07H				;
;--------------------------


L_SENSOR		BIT		P1.2
R_SENSOR		BIT		P1.3
IN1				BIT		P1.4
IN2				BIT	 	P1.5
IN3				BIT	 	P1.6
IN4				BIT		P1.7

P_MOTOR			EQU		P1

;===================================================================
				ORG 	0000H
				lJMP	MAIN
				LJMP	INT0_ISR

				ORG		000BH
				LJMP	T0_ISR

				ORG 	0013H
				LJMP	INT1_ISR

				ORG		001BH
				LJMP	T1_ISR

				ORG 	0023H
				LJMP	SPI_ISR
						  	
;=============================================
				ORG  	0033H
MAIN:		
				MOV 	SP,#4FH


				;---------------------
				CALL	INITIAL					;LCD	
				MOV		DPTR,#TAB_LINE1
				CALL	PRINT_LINE

				MOV		A,#0C0H
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT

				MOV		DPTR,#TAB_LINE2
				CALL	PRINT_LINE
				;---------------------
				SETB	EA						;NGAT TOAN CUC
				MOV		IP,#02H	 				;UU TIEN NGAT T0
				;----------------
				MOV		TMOD,#11H				;T1 ADC / T0 PWM											 		
				;----------------------
												;2 DONG CO
				MOV		30H,#HIGH(-720)			;FFB0H = -80
				MOV		31H,#LOW(-720)
				MOV		32H,#HIGH(-80)			;FD30H = -720
				MOV		33H,#LOW(-80)
				MOV		34H,#9
				;----------------------
				SETB	ET0
				SETB	TF0					;EP NGAT TIMER 0
				;------------------
				SETB	IT0					;NGAT CANH XUONG
				SETB	EX0
				;-------------------
				SETB	ET1
				SETB	TR1					;EP NGAT TIMER 1
				;------------------

LOOP_00:		
				MOV		A,34H
				CJNE	A,35H,SPEED_CHANGE
				SJMP	LOOP_01

SPEED_CHANGE:	
				MOV		35H,34H			;SAVE OLD STATE
				CALL	WRITE_SPEED
				;--------------			FLAG3 XOR  FLAG5
LOOP_01:		
				MOV		C,FLAG3
				JNC		LOOP_02				
				MOV		C,FLAG5
				CPL		C
				JMP		LOOP_03					
LOOP_02:		MOV		C,FLAG5
				;-------------
LOOP_03:		
				JNC		LOOP_00
				
				MOV		C,FLAG3	 		;SAVE OLD STATE
				MOV		FLAG5,C
				SETB	EA
				CALL	WRITE_STATE	
										  
				SJMP	LOOP_00

				
TAB_LINE1:		DB		'STATE :     LINE'
TAB_LINE2:		DB		'SPEED :        %'

;=========================================================
PRINT_LINE:		MOV		R0,#16
				MOV		A,#0
PRINT_LINE_1:	PUSH	ACC
				CALL	PRINT_CHAR
				POP		ACC
				INC		A
				DJNZ	R0,PRINT_LINE_1
				RET

;=========================================
PRINT_CHAR:	
				MOVC	A,@A+DPTR
				CJNE	A,#00H,PRINT_CHAR1
				SETB	C
				RET
PRINT_CHAR1:	CALL	DELAY_2MS
				SETB	RS
				PUSH	DPH
				PUSH	DPL
				CALL	WRITE_OUT
				POP		DPL
				POP		DPH
				CLR		C
PRINT_CHAR2:	RET
;--------------------------------------------

WRITE_STATE:					
				MOV		A,#88H			;CHUYEN CON TRO VE 08H
				CALL	DELAY_2MS				
				CLR		RS
				CALL	WRITE_OUT

				JB		FLAG5,IN_LINE

				MOV		39H,#'O'
				MOV		3AH,#'U'
				MOV		3BH,#'T'								
				JMP		EXIT_WRITE_STATE
IN_LINE:
				MOV		39H,#' '
				MOV		3AH,#'I'
				MOV		3BH,#'N'
				
EXIT_WRITE_STATE:
				MOV		R1,#39H									
				CALL	WRITE_RAM
				RET
;---------------------------------------------
WRITE_SPEED:
				MOV		A,#0CCH			;CHUYEN CON TRO VE 4CH
				CALL	DELAY_2MS				
				CLR		RS
				CALL	WRITE_OUT

				MOV		A,35H				
				CJNE	A,#10,WRITE_SPEED_00

				MOV		36H,#'1'
				MOV		37H,#'0'
				MOV		38H,#'0'								
				JMP		WRITE_SPEED_01
				
WRITE_SPEED_00:
				MOV		36H,#' '
				MOV		A,#30H
				ADD		A,35H
				MOV		37H,A
				MOV		38H,#'0'
				
WRITE_SPEED_01:	MOV		R1,#36H								
				CALL	WRITE_RAM			
				RET
				;--------------------------
WRITE_RAM:												;NAP R1 VO TRUOC KHI CALL
				;MOV		R1,#36H
				MOV		R2,#3
WRITE_RAM_00:	MOV		A,@R1
				CALL	DELAY_2MS
				SETB	RS
				CALL	WRITE_OUT
				INC		R1
				DJNZ	R2,WRITE_RAM_00
				RET
;---------------------------------------------

INITIAL:		
				CLR		EN								;do EN tich cu muc cao (khong co lenh nay cung khong sao)
				MOV		A,#38H	 		;8 bits 5x8 dots
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				MOV		A,#01H		  	;clscr
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				MOV		A,#0FH		   	;Hien man hinh, chop ky tu
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				MOV		A,#06H		  	;Dich con tro sang phai (khi ghi/doc data)
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				RET
 ;---------------------------------------------------------------
DELAY_2MS:		
				MOV		R7,#4
DELAY_2MS_0:	MOV		R6,#250
				DJNZ	R6,$
				DJNZ	R7,DELAY_2MS_0
				RET
				;---------------------

DELAY_120us:	
				MOV		R5,#60
				DJNZ	R5,$
				RET
;-----------------------------------------------------------------

WRITE_OUT:		
				MOV		BUS_LCD,A
				SETB	EN
				CLR		EN
				RET
;============================================

INT0_ISR:	
				PUSH	ACC
				PUSH	PSW	
				PUSH	82H
				PUSH	83H			
				CLR		ET0

				MOV		R3,#50
				SETB	P3.2					;DUA CHOT PORT LEN 1 ROI MOI DOC
CHECK_SW:		MOV		C,P3.2
	    		JC		EXIT_INT0_ISR
				DJNZ	R3,CHECK_SW
				
				INC		34H
				MOV		A,34H

				CJNE	A,#11,INT0_ISR_0
				MOV		34H,#1
				MOV		30H,#HIGH(-80)			;FFB0H = -80
				MOV		31H,#LOW(-80)
				MOV		32H,#HIGH(-720)			;FD30H = -720
				MOV		33H,#LOW(-720)

				SJMP	EXIT_INT0_ISR
INT0_ISR_0:					
				MOV		A,31H
				CLR		C
				SUBB	A,#80
				JNC		INT0_ISR_1
				DEC		30H
INT0_ISR_1:		MOV		31H,A

				MOV		A,33H
				ADD		A,#80
				JNC		INT0_ISR_2
				INC		32H
INT0_ISR_2:		MOV		33H,A
				
EXIT_INT0_ISR:	
				SETB	ET0
				POP		83H
				POP		82H
				POP		PSW
				POP		ACC
				RETI
;=============================================

T0_ISR:												;0.8 MS = 1.25 KHZ
				PUSH	ACC
				PUSH	PSW
				PUSH	82H
				PUSH	83H
				CLR		EA

				CLR		TR0
				MOV		A,34H
				CJNE	A,#10,T0_ISR_01

				MOV		TH0,HIGH(-800)										  	
				MOV		TL0,LOW(-800)

				SETB	TR0
				SETB	FLAG0
				JMP		RUN_MOTOR
				;---------------------------

T0_ISR_01:		JNB		FLAG0,NON_DUTY

				CLR		FLAG0
				MOV		TH0,30H						;THOI GIAN MUC 0				  	
				MOV		TL0,31H
				SETB	TR0
				
				JMP		RUN_MOTOR
				;---------------------------
NON_DUTY:		
				SETB	FLAG0

				MOV		TH0,32H					  	;THOI GIAN MUC 1
				MOV		TL0,33H
				SETB	TR0
				
				JMP		STOP_MOTOR
				;---------------------------
RUN_MOTOR:		
				JNB		FLAG1,RUN_MOTOR_1
				SETB	IN1						;CHAY BANH TRAI	 ;1 QUAY THUAN
				CLR		IN2

RUN_MOTOR_1:	JNB		FLAG2,EXIT_T0_ISR
				SETB	IN3						;CHAY BANH PHAI
				CLR		IN4

				SJMP	EXIT_T0_ISR
				;--------------------------
STOP_MOTOR:
				ANL		P_MOTOR,#0FH

EXIT_T0_ISR:
				POP		83H
				POP		82H
				POP		PSW
				POP		ACC
				SETB	EA
				RETI
;=============================================
INT1_ISR:	

				RETI
;=============================================
T1_ISR:		
				PUSH	ACC
				PUSH	PSW	
				PUSH	82H
				PUSH	83H			

				CLR		TR1				
				MOV		TH1,HIGH(-1000)
				MOV		TL1,LOW(-1000)
				SETB	TR1

				CLR		EA
				SETB	L_SENSOR
				MOV		C,L_SENSOR
				MOV		FLAG1,C
				
				SETB	R_SENSOR
				MOV		C,R_SENSOR
				MOV		FLAG2,C
				;-----------------

				MOV		C,FLAG1
				JNC		T1_ISR_01				
				MOV		C,FLAG2
				CPL		C
				JMP		T1_ISR_02					
T1_ISR_01:		MOV		C,FLAG2
				;-------------
T1_ISR_02:
				JC		T1_ISR_03
				SETB	FLAG1					;GIONG, CUNG TRONG CUNG NGOAI => CHAY THANG
				SETB	FLAG2

				JNB		FLAG1,CLR_FLAG3
				SETB	FLAG3
				JMP		EXIT_T1_ISR

CLR_FLAG3:		CLR		FLAG3
				JMP		EXIT_T1_ISR
T1_ISR_03:
			  	JNB		FLAG1,TURN_RIGHT
				CLR		FLAG1  					;TURN LEFT
				SETB	FLAG2
				CLR		FLAG3
				JMP		EXIT_T1_ISR
TURN_RIGHT:
				SETB	FLAG1
				CLR		FLAG2
				SETB	FLAG3
EXIT_T1_ISR:				
				POP		83H
				POP		82H
				POP		PSW
				POP		ACC	
				SETB	EA			
				RETI


;=============================================				
SPI_ISR:		
	
				RETI	
																			
				END


