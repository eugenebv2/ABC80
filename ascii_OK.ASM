USERTK	.EQU	0F7AFH
SYSSTK	.EQU	0F7BFH
STEPBF	.EQU	0F7BFH
STRTAP	.EQU	0F7C1H
EADTAP	.EQU	0F7C3H
SUMTAP	.EQU	0F7C5H
DISPBF	.EQU	0F7C6H
ADDBF	.EQU	0F7C8H
ADSAVE	.EQU	0F7EEH
PCSAVE	.EQU	0F7E2H
SPSAVE	.EQU	0F7E0H
IYSAVE	.EQU	0F7E0H
STMONI	.EQU	0F7F3H
STATE	.EQU	0F7F4H
PWUP	.EQU	0F7F5H
TEST	.EQU	0F7F6H
ATEMP	.EQU	0F7F7H
HLTEMP	.EQU	0F7F8H
TEMP	.EQU	0F7FAH

MIDPD:	.equ	2AH
PWCODE	.EQU	80H
CPMS	.EQU	1840	; Mhz Clock for Delay subroute
;CPMS	.EQU	3680	; Mhz Clock for Delay subroute

KIN	.EQU	40H	; port A
SEG7	.EQU	41H	; port B
DIGIT	.EQU	42H	; port C
P8255	.EQU	43H	; Control Register

	.ORG	0000H

RST0:	LD	B,00H		;power on delay then begin
	DJNZ	$
	JP	BEGIN

	.ORG	0038H

BREAK:	LD	(TEMP),HL	;save 13F8 to L, 13F9 to H
	POP	HL

	LD	(ADSAVE),HL	;save PC to ADSAVE, PC(H) to 13E3,PC(L) to 13E2
	LD	(PCSAVE),HL

	LD	HL,(TEMP)
	LD	(SPSAVE),SP	;save SP(H) to 13E1, SP(L) to 13E0

	LD	SP,(IYSAVE)	;save IY(H) to 13DF, IY(L) to 13DE
	PUSH	IY

	PUSH 	IX		;save IX(H) to 13DD, IX(L) to 13DC
	EXX

	PUSH 	HL
	PUSH	DE
	PUSH	BC
	EXX

	EX 	AF,AF'
	PUSH	AF
	EX	AF,AF'

	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	JP	RST0

NMI:

	.ORG	0070H

BEGIN:	LD	A,90H		; D7=1,portA:mode0,input,portC:output,portB:mode0,output
	OUT	(P8255),A	; port A: keypad, port B,C 7 seg LED
	
	LD	A,00H		
	OUT	(DIGIT),A

;	LD	A,0BFH		; Display 000000
;	OUT	(SEG7),A
;	CALL	MS05K0

;	LD	B,4		; Delay 1 sec ?
;	LD	A,250
;	CALL	DELAY

	LD	SP,SYSSTK
	LD	A,(PWUP)
	CP	PWCODE

	CALL	NZ,INIT
	CALL	RSTMU

	LD	HL,9000H	; memory start address
	LD	(ADSAVE),HL
	
	XOR	A
	LD	(TEST),A

	LD	IX,DISP
	
SETST0:	XOR	A
	LD	(STATE),A
	NOP
	NOP
	NOP

MAIN:	
	CALL	SCDSK
	CALL	MS3K0
	CALL	CHKEY

	JP	MAIN
	
	.ORG	00A9H

CHKEY:	CP	10H
	JR	C,KHEX

	LD	HL,TEST
	SET	0,(HL)

	SUB	10H
	CP	04H
	LD	HL,SUBFUN
	JP	C,BRANCH

	LD	IX,DISPBF
	SUB	02H
	LD	HL,STATE
	LD	(HL),A
	
	LD	HL,STMONI
	LD	(HL),00H

	LD	HL,FUNC
	SUB	02H
	JP	BRANCH

	.ORG	00D4H

KHEX:	LD	C,A
	LD	HL,HTAB
PREBR:	LD	A,(STATE)
	JP	BRANCH

KINC:	LD	HL,ITAB
	JR	PREBR

KDEC:	LD	HL,DTAB
	JR	PREBR

KEXEC:	LD	HL,ETAB
	JR	PREBR

KDATA:	CALL	TESTM
	CALL	DFORM2
	RET

KADRS:	CALL	DFORM1
	RET

KTAPWR:	CALL	STEPDP
	RET
;=========================================00FFH
	.ORG	00FFH

HFIX:	JP	ERRDIS

HDA:	LD	HL,(ADSAVE)
	CALL	RAMCHK
	JP	NZ,ERRDIS
	CALL	CL1BYT
	LD	A,C
	RLD
	CALL	DFORM2
	RET
;=========================================0116H
	NOP

HAD:	LD	HL,ADSAVE
	CALL 	CL2BYT
	LD	A,C
	RLD
	INC	HL
	RLD
	CALL	DFORM1
	RET
;=========================================0127H
	NOP

HTAPWR:	CALL	GTPALC
	CALL	CL2BYT
	LD	A,C
	RLD
	INC	HL
	RLD
	CALL	STEPDP
	RET
;=========================================013AH
	NOP
	NOP
	NOP

IFIX:	JP	ERRDIS

ADRADD:	LD	HL,(ADSAVE)
	INC	HL
	LD	(ADSAVE),HL
	CALL	DFORM2
	RET
;=========================================0149H
	NOP

TPFUN1:	LD	HL,STMONI
	INC	(HL)
	CALL	GTPANA
	JR	NZ,ISTEP
	DEC 	(HL)
	JP	ERRDIS

ISTEP:	CALL	STEPDP
	RET
;=========================================015DH
	NOP
	NOP
	NOP

DFIX:	JP	ERRDIS

ADRDEC:	LD	HL,(ADSAVE)
	DEC	HL
	LD	(ADSAVE),HL
	CALL	DFORM2
	RET
;=========================================016CH
	NOP

TPFUN2:	LD	HL,STMONI
	DEC	(HL)
	CALL	GTPANA
	JR	NZ,DSTEP
	INC	(HL)
	JP	ERRDIS

DSTEP:	CALL	STEPDP
	RET
;==========================================0180H
	NOP
	NOP
	NOP	

EFIX:	JP	ERRDIS

ADREXC:	PUSH	HL
	LD	HL,(ADSAVE)
	EX	(SP),HL
	RET
;==========================================
	.ORG	018AH

ENDFUN:	LD	(ADSAVE),DE
	CALL	DFORM2
	RET


;==========================================
	.ORG	0193H

EWT:	CALL	SUM
	JR	C,ERROR
	LD	(SUMTAP),A
	LD	HL,0FAH
	CALL	MS1K
	LD	HL,STEPBF
	LD	BC,0007H
	CALL	TAPOUT
	LD	HL,0FA0H
	CALL	MS2K
	CALL 	GETPTR
	CALL	TAPOUT
	LD	HL,0FA0H
	CALL	MS2K
ENDTAP:	LD	DE,(EADTAP)
	JR	ENDFUN

;==========================================
	.ORG	01C3H

ERROR	LD	IX,MERR
	JP	SETST0

;==========================================
	.ORG	01CEH

EPT:	LD	HL,(STEPBF)
	LD	(TEMP),HL
LEAD:	LD	A,0BFH
	OUT	(SEG7),A
	LD	HL,1000
LEAD1:	CALL	PERIOD
	JR	C,LEAD
	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,LEAD1

LEAD2:	CALL	PERIOD
	JR	NC,LEAD2
	LD	HL,STEPBF
	LD	BC,7
	CALL	TAPEIN
	JR	C,LEAD
	LD	DE,(STEPBF)
	CALL	ADRSDP
	LD	B,150
FILEDP:	CALL	SCDSK1
	DJNZ	FILEDP
	LD	HL,TEMP
	OR	A
	SBC	HL,DE
	JR	NZ,LEAD
	LD	A,11111101B
	OUT	(SEG7),A
	CALL	GETPTR
	JR	C,ERROR
	CALL	TAPEIN
	JR	C,ERROR
	CALL	SUM
	LD	HL,SUMTAP
	CP	(HL)
	JR	NZ,ERROR
	JR	ENDTAP

;==========================================
	.ORG	02BBH

GETPTR:	LD	HL,STRTAP
GETP:	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	C,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,C
	OR	A
	SBC	HL,DE
	LD	C,L
	LD	B,H
	INC	BC
	EX	DE,HL
	RET

TAPEIN:	XOR	A
	EX	AF,AF'
TLOOP:	CALL	GTBYTE
	LD	(HL),E
	CPI
	JP	PE,TLOOP
	EX	AF,AF'
	RET

GTBYTE:	CALL 	GETBIT
	LD	D,08H
GLOOP:	CALL	GETBIT
	RR	E
	DEC	D
	JR	NZ,GLOOP
	CALL	GETBIT
	RET

GETBIT:	EXX
	LD	HL,0000H
COUNT:	CALL	PERIOD
	INC	D
	DEC	D
	JR	NZ,TERR
	JR	C,SHORTP
	DEC	L
	DEC	L
	SET	0,H
	JR	COUNT
SHORTP:	INC	L
	BIT	0,H
	JR	Z,COUNT
	RL	L
	EXX
	RET

TERR:	EX	AF,AF'
	SCF
	EX	AF,AF'
	EXX
	RET

PERIOD:	LD	DE,0000H
CHK0:	IN	A,(KIN)
	INC	DE
	RLA
	JR	C,CHK0
	LD	A,01000000B
	OUT	(DIGIT),A
CHK1:	IN	A,(KIN)
	INC	DE
	RLA
	JR	NC,CHK1
	LD	A,0C0H
	OUT	(DIGIT),A
	LD	A,E
	CP	MIDPD
	RET

TAPOUT:	LD	E,(HL)
	CALL	OTBYTE
	CPI
	JP	PE,TAPOUT
	RET

OTBYTE:	LD	D,08H
	OR	A
	CALL	OUTBIT
OLOOP:	RR	E
	CALL	OUTBIT
	DEC	D
	JR	NZ,OLOOP
	SCF
	CALL	OUTBIT
	RET

OUTBIT:	EXX
	LD	H,00H
	JR	C,OUT1
OUT0:	LD	L,0CH
	CALL	MS2K
	LD	L,03H
	JR	BITEND
OUT1:	LD	L,06H
	CALL	MS2K
	LD	L,06H
BITEND:	CALL	MS1K
	EXX
	RET
;=========================================
	.ORG	036AH

BRANCH:	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	ADD	A,L
	LD	L,A
	LD	L,(HL)
	LD	H,00H
	ADD	HL,DE
	JP	(HL)

ERRDIS:	LD	HL,TEST
	SET	7,(HL)
	RET
;=========================================
	NOP

CL1BYT:	LD	A,(TEST)
	OR	A
	RET	Z

	LD	A,00H
	LD	(HL),A
	LD	(TEST),A
	RET
;=========================================
	NOP

CL2BYT:	CALL	CL1BYT
	RET 	Z
	INC	HL
	LD	(HL),A
	DEC	HL
	RET
;=========================================
	NOP

DFORM1:	LD	A,01H
	LD	B,04H
	LD	HL,ADDBF
	JR	SAV12

DFORM2:	LD	A,02H
	LD	B,02H
	LD	HL,DISPBF

SAV12:	LD	(STATE),A
	EXX
	LD	DE,(ADSAVE)
	CALL	ADRSDP
	LD	A,(DE)
	CALL	DADP
	EXX
SETPT:	SET	6,(HL)
	INC	HL
	DJNZ	SETPT
	RET
;=========================================
	NOP

STEPDP:	CALL	GTPALC
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	CALL	ADRSDP
	LD	HL,ADDBF
	LD	B,04H
	CALL	SETPT
	CALL	GTPANA
	LD	L,A
	LD	H,02H
	LD	(DISPBF),HL
	RET

;=========================================
	.ORG	03D5H

GTPALC:	LD	A,(STMONI)
	ADD	A,A
	LD	HL,STEPBF
	ADD	A,L
	LD	L,A
	RET
;=========================================
	.ORG	03E0H

GTPANA:	LD	A,(STATE)
	SUB	01H		; SUB 	A,01H
	ADD	A,A
	ADD	A,A
	LD	DE,BLANK
	ADD	A,E
	LD	E,A
	LD	A,(STMONI)
	ADD	A,E
	LD	E,A
	LD	A,(DE)
	OR	A
	RET
;=========================================03F5H
	NOP

INIDP:	LD	IX,INITTAB
	LD	C,15H
INIDP1:	LD	B,20H		; show next char delay
INIDP2:	CALL	SCDSK1
	DJNZ	INIDP2
	DEC	IX
	CALL	MS05K0
	DEC	C
	JR	NZ,INIDP1
	RET
;=========================================040CH
	NOP

MONSOU:	LD	IY,SONG
MUSIC:	PUSH	IY
	POP	IX
	LD	A,(IX)
	ADD	A,A
	JR	C,STOP
	JP	M,MUSIC
	BIT	6,A
	JR	NZ,PLAY
	SET	7,C
PLAY:	AND	3FH
	LD	HL,FRQTAB
	ADD	A,L
	LD	L,A
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	IX
	LD	H,(IX)
	LD	A,0FFH
TONE:	LD	L,D
TONOUT:	OUT	(DIGIT),A
	LD	B,E
DELAY1:	NOP
	NOP
	NOP
	DJNZ	DELAY1
	XOR	C
	DEC	L
	JR	NZ,TONOUT
	DEC	H
	JR	NZ,TONE
	INC	IX		; get next sound
	JR	MUSIC+4
STOP:	RET

; 
;	make 500Hz 1KHz 2KHz 3KHz Sound
;
MS05K0:	EX	AF,AF'
	EXX
	LD	HL,0050H
	CALL	MS05K
	EXX
	EX	AF,AF'
	RET

MS1K0:	EXX
	LD	HL,0050H
	CALL	MS1K
	EXX
	RET

MS2K0:	EXX
	LD	HL,00A0H
	CALL	MS2K
	EXX
	RET

MS3K0:	EX	AF,AF'
	EXX
	LD	HL,00E0H
	CALL	MS3K
	EXX
	EX	AF,AF'
	RET

MS05K:	LD	C,89H
	JR	SOUND
MS1K:	LD	C,41H
	JR	SOUND
MS2K:	LD	C,1FH
	JR	SOUND
MS3K:	LD	C,0CH
SOUND:	ADD	HL,HL
	LD	DE,0001H
	LD	A,0FFH
SQWAVE:	OUT	(DIGIT),A
	LD	B,C	
	DJNZ	$
	XOR	80H
	SBC	HL,DE
	JR	NZ,SQWAVE
	RET

;
; Summary memory length from start to end
;
SUM:	CALL	GETPTR
	RET	C
	XOR	A
SUMCAL:	ADD	A,(HL)
	CPI
	JP	PE,SUMCAL
	OR	A
	RET

RAMCHK:	LD	A,(HL)
	CPL
	LD	(HL),A
	LD	A,(HL)
	CPL
	LD	(HL),A
	CP	(HL)
	RET
;

;
; scan display and keypad, SCDSK get key monitor data, SCDSK1 get keypad data
;
SCDSK:	PUSH	IX
	LD	HL,TEST
	BIT	7,(HL)
	JP	Z,SCPRE
	LD	IX,MERR
SCPRE:	LD	B,04H
SCNX:	CALL	SCDSK1
	JR	NC,SCPRE
	DJNZ	SCNX
	RES	7,(HL)
	POP	IX
SCLOOP:	CALL	SCDSK1
	JR	C,SCLOOP
KEYMAP	LD	HL,MAP
	ADD	A,L
	LD	L,A
	LD	A,(HL)	
	RET
;
;	SCDSK1 get keypad data	04CDH
;
SCDSK1:	SCF
	EX	AF,AF'
	EXX
	LD	C,00H
	LD	E,0FEH		; 0FEH

KCOL	LD	A,(IX)
	CPL			; 共陽不需要轉換
	OUT	(SEG7),A
	LD	A,E
;	CPL			; 共陽需要轉換
	OUT	(DIGIT),A

;	LD	B,1
;	LD	A,1
;	CALL	DELAY

	LD	B,40H		; Delay
	DJNZ	$

	LD	B,06H
	IN	A,(KIN)
	LD	D,A
KROW	RR	D
	JR	C,NOKEY
	LD	A,C
	EX	AF,AF'
	
NOKEY	INC	C
	DJNZ	KROW

	INC	IX
	RLC	E		; next led ( Rotate contents of E left one bit,
	LD	A,0FFH
	OUT	(DIGIT),A
	BIT	6,E
	JR	NZ,KCOL
	LD	DE,-6
	ADD	IX,DE
	EXX
	EX	AF,AF'
	RET

ADRSDP:	LD	HL,ADDBF
	LD	A,E
	CALL	TBYSEG
	LD	A,D
	CALL	TBYSEG
	RET

DADP:	LD	HL,DISPBF	; convert Byte to display char
	CALL	TBYSEG
	RET

OBYSEG:	PUSH	HL
	LD	HL,SEGTAB
	AND	0FH
	ADD	A,L
	LD	L,A
	LD	A,(HL)
	POP	HL
	RET

TBYSEG:	PUSH	AF		; two byte seg
	CALL	OBYSEG
	LD	(HL),A
	INC	HL
	POP	AF
	RRCA
	RRCA
	RRCA
	RRCA
	CALL	OBYSEG
	LD	(HL),A
	INC	HL
	RET

TESTM:	LD	A,(STATE)
	CP	01H
	RET	Z
	CP	02H
	RET	Z
	POP	HL
	JP	ERRDIS
RSTMU:	LD	IY,RMUSIC
	CALL	MUSIC
	RET

INIT:	
	CALL	INIDP
;	CALL	MONSOU
	LD	A,PWCODE
	LD	(PWUP),A
	RET

; ==================================================================
DELAY:
	PUSH 	BC 		;11 CYCLES
	CALL 	DLY 		;32 CYCLES TO RETURN FROM DLY
				;DO 2 LESS THAN 1 MILLISECOND FOR OVERHEAD
	LD B,+(CPMS/50)-2	;7 CYCLES

LDLP:				;67 CYCLES
	JP 	LDLY1 		;10 CYCLES
LDLY1:	JP 	LDLY2 		;10 CYCLES
LDLY2:	JP 	LDLY3 		;10 CYCLES
LDLY3:	ADD 	A,0 		;7 CYCLES
	DJNZ 	LDLP 		;13 CYCLES---50 CYCLES EXIT IN 33 CYCLES
	POP 	BC 		;10 CYCLES
	LD 	A,(DELAY) 	; 13 CYCLES
	RET
DLY:	
	DEC	A
	RET	Z
	LD	B,+(CPMS/50)-1
DLP:	
	JP 	DLY1 		;10 CYCLES
DLY1:	JP 	DLY2 		;10 CYCLES
DLY2:	JP 	DLY3 		;10 CYCLES
DLY3:	ADD 	A,0 		;7 CYCLES
	DJNZ 	DLP 		;13 CYCLES	
	JP	DLY4
DLY4:	JP	DLY5
DLY5:	NOP	
	JP	DLY
;===================================================================

SONG:	.DW	0210H
	.DW	0211H
	.DW	0210H
	.DW	020CH
	.DW	1809H
	.DW	021CH
	.DW	021DH
	.DW	021CH
	.DW	0218H
	.DW	1815H
	.DW	0210H
	.DW	0215H
	.DW	0211H	; 1.
	.DW	0210H	; 7
	.DW	020CH	; 5
	.DW	1809H	;
	.DW	021CH
	.DW	021FH
	.DW	021DH
	.DW	021CH
	.DW	0218H
	.DW	1815H	;
	.DW	0809H
	.DW	0409H
	.DW	040CH
	.DW	080EH
	.DW	0410H
	.DW	040CH
	.DW	1809H
	.DW	0820H	; ST-
	.DW	0809H
	.DW	040CH
	.DW	0409H
	.DW	080CH
	.DW	040EH	
	.DW	0413H
	.DW	1810H
	.DW	0820H	; ST-
	.DW	0C10H
	.DW	0413H
	.DW	0C15H
	.DW	0410H
	.DW	040EH
	.DW	0409H
	.DW	040CH
	.DW	040EH
	.DW	0F10H
	.DW	080CH
	.DW	040EH
	.DW	040BH
	.DW	0809H	
	.DW	0409H
	.DW	0407H
	.DW	1809H
	.DW	0210H
	.DW	0211H
	.DW	0210H
	.DW	020CH
	.DW	1809H
	.DW	021CH
	.DW	021DH
	.DW	021CH
	.DW	0218H
	.DW	1815H
	.DW	0210H
	.DW	0215H
	.DW	0211H
	.DW	0210H
	.DW	020CH
	.DW	1809H
	.DW	021CH
	.DW	021FH
	.DW	021DH
	.DW	021CH
	.DW	0218H
	.DW	1815H
	.DW	80H	; RT-
	.DW	0FFH

RMUSIC:	.DW	021CH
	.DW	021DH
	.DW	021CH
	.DW	0218H
	.DW	0815H
	.DW	80H

SUBFUN:	.DW	00DEH
	.DB	00H
	.DB	05H
	.DB	0AH
	.DB	0FH

FUNC:	.DW	00F4H
	.DB	00H
	.DB	04H
	.DB	04H

HTAB:	.DW	00FFH
	.DB	00H
	.DB	17H
	.DB	03H
	.DB	28H
	.DB	28H

ITAB:	.DW	013AH
	.DB	00H
	.DB	03H
	.DB	03H
	.DB	0FH
	.DB	0FH

DTAB:	.DW	015DH
	.DB	00H
	.DB	03H
	.DB	03H
	.DB	0FH
	.DB	0FH

ETAB:	.DW	0180H
	.DB	00H
	.DB	03H
	.DB	03H
	.DB	13H
	.DB	4EH

FRQTAB:	.DW	18E1H	; 00	 5!
	.DW	1AD4H	; 01	#5!
	.DW	1BC8H	; 02	 6!	
	.DW	1DEDH	; 03	#6!
	.DW	1EB2H	; 04	 7!
	.DW	20A8H	; 05	 1
	.DW	229FH	; 06	#1	
	.DW	2496H	; 07	 2
	.DW	268DH	; 08	#2
	.DW	2985H	; 09	 3
	.DW	2B7FH	; 0A	 4
	.DW	2E77H	; 0B	#4
	.DW	3170H	; 0C	 5
	.DW	336AH	; 0D	#5
	.DW	3764H	; 0E	 6
	.DW	3A5EH	; 0F	#6
	.DW	3D59H	; 10	 7
	.DW	4154H	; 11	 1.
	.DW	454FH	; 12	#1.
	.DW	494AH	; 13	 2.
	.DW	4D46H	; 14	#2.	
	.DW	5242H	; 15	 3.
	.DW	573EH	; 16	 4.
	.DW	5C3BH	; 17	#4.
	.DW	6237H	; 18	 5.
	.DW	6734H	; 19	#5.	
	.DW	6E31H	; 1A	 6.
	.DW	742EH	; 1B	#6.
	.DW	7B2CH	; 1C	 7:
	.DW	8229H	; 1D	 1:
	.DW	8A27H	; 1E	#1:
	.DW	9225H	; 1F	 2:
	
MAP:	.DB	14H	; ADRS
	.DB	13H	; DATA
	.DB	11H	; DEC
	.DB	10H	; INC
	.DB	0FFH
	.DB	0FFH
	.DB	0FH	; F
	.DB	0BH	; B
	.DB	07H	; 7
	.DB	03H	; 3
	.DB	0FFH
	.DB	0FFH
	.DB	0EH	; E
	.DB	0AH	; A
	.DB	06H	; 6
	.DB	02H	; 2
	.DB	0FFH
	.DB	0FFH
	.DB	0DH	; D
	.DB	09H	; 9
	.DB	05H	; 5
	.DB	01H	; 1
	.DB	0FFH
	.DB	0FFH
	.DB	0CH	; C
	.DB	08H	; 8
	.DB	04H	; 4
	.DB	00H	; 0
	.DB	0FFH
	.DB	0FFH	
	.DB	0FFH
	.DB	15H	; TO TAPE
	.DB	16H	; FROM TAPE
	.DB	12H	; EXEC

DISP:	.DB	0BDH	; 0
	.DB	0BFH	; 8
	.DB	02H	; -
	.DB	8DH	; C
	.DB	0A7H	; B
	.DB	3FH	; A
	.DB	00H	; 
	.DB	0AEH	; S
	.DB	30H	; I
	.DB	00H	; 
	.DB	0AEH	; S
	.DB	30H	; I
	.DB	37H	; H
	.DB	87H	; t
	.DB	00H	;
	.DB	0BDH	; O
	.DB	85H	; L
	.DB	85H	; L
	.DB	8FH	; E
INITTAB: .DB	37H	; H
	.DB	00H	; " "
	.DB	00H	; " "	
	.DB	00H	; " "
	.DB	00H	; " "
	.DB	00H	; " "
	.DB	00H	; " "
MERR:	.DB	03H	; R
	.DB	0A3H	; O
	.DB	03H	; R
	.DB	03H	; R
	.DB	8FH	; E
	.DB	02H	; -
	.DB	00H	; " "
BLANK:	.DB	00H	; " "
	.DB	00H	; " "
	.DB	00H	; " "	
	.DB	00H	; " "
	.DB	00H	; " "
	.DB	00H	; " "
	.DB	00H	; " "
	.DB	00H	; " "

	.DB	0FH	; F	; TO TAPE FILENAME
	.DB	0AEH	; S	; TO TAPE START ADDRESS
	.DB	8FH	; E	; TO TAPE END ADDRESS
	.DB	00H	; " "
	.DB	4FH	; F.	; FROM TAPE FILENAME	
	.DB	0EEH	; S.	; FROM TAPE START ADDRESS
	.DB	0CFH	; E.	; FROM TAPE END ADDRESS
	.DB	00H	; " "

SEGTAB:	.DB	0BDH	; 0
	.DB	30H	; 1
	.DB	9BH	; 2
	.DB	0BAH	; 3
	.DB	36H	; 4
	.DB	0AEH	; 5
	.DB	0AFH	; 6
	.DB	38H	; 7
	.DB	0BFH	; 8
	.DB	0BEH	; 9
	.DB	3FH	; A
	.DB	0A7H	; B lower case
	.DB	8DH	; C
	.DB	0B3H	; D lower case
	.DB	8FH	; E
	.DB	0FH	; F

	.END
