<CsoundSynthesizer>
<CsOptions>
; -o123890123.wav 
-odac
-d
--daemon
-M0
-+rtaudio=jack
-+rtmidi=jack
</CsOptions>
<CsInstruments>

; sr = 55937.5
sr = 44100
ksmps = 64
nchnls = 1
0dbfs = 1

massign 0, 4

giW1 ftgen 1, 0, 4096, 10, 1
giW2 ftgen 2, 0, 4096, 2, 0 
giW3 ftgen 3, 0, 4096, 2, 0
giW4 ftgen 4, 0, 4096, 2, 0
giW5 ftgen 5, 0, 4096, 2, 0
giW6 ftgen 6, 0, 4096, 2, 0
giW7 ftgen 7, 0, 4096, 2, 0
giW8 ftgen 8, 0, 4096, 2, 0
giVel init 0 ; velocity 

giAR ftgen 9, 0, 32, -2, 0,647829,452377,322874,225473,160445,112801,80602,56434,40244,28328,
20297,14152,10306,7237,5231,3687,2601,1765,1417,1000,822,572,440,400,380,310,278,165,135,130,125
giD1R ftgen 10,0,32,-2, -1000,3116605/*0*/,2179104/*1*/,1547622/*2*/,1086731/*3*/,778176/*4*/,542607/*5*/,389089/*6*/,272208/*7*/,450000/*316000/*8*/,137953/*9*/,;������� 9-� ��������, ���� 193554
98004/*10*/,69000/*11*/,48235/*12*/,34239/*13*/,24524/*14*/,36000/*17512/*15*/,27000/*12895/*16*/,13859/*17*//*���� 8843*/,5774,4387,3254,2040,1573,955,925,575,475,200,125,1,1;!!!! ������ ���� ���� , �� ��� �������� � ������ ������� �� 0
giD2R ftgen 11,0,32,-2, -1000,3101310,2168831,1551896,1084546,771475,541448,387275,270054,192173,134025,
96252,67545,47431,34174,24459,17359,11987,8775,6000,4302,2885,2136,1415,1000,700,677,355,331,254,1,1;!!!! ������ ���� ���� 
giRR ftgen 12,0,16,-2,0,1559542,779813,386094,192749,97322,48481,24041,11808,6038,2957,1570,858,350,
118,1;!!!! ������ ���� ���� 
giD1L ftgen 13,0,16,-2, 0,0.007943,0.01122,0.015849,0.022387,0.031623,0.044668,0.063096,0.089125,0.125893,
0.177828,0.251189,0.358922,0.506991,0.716143,1
giNOTE ftgen 14,0,128,-2,24,13,14,15,16,17,18,19,20,21,22,23,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,
28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,
61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,
94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,98,99,100,101,102,103,104,105,106,107,
108,97,98,99,100,101,102,103
giVOL ftgen 15,0, 128,-2,0.000254,0.000254,0.000254,0.000254,0.000254,0.000254,0.000254,0.000254,0.000254,
0.000254,0.000254,0.000254,0.000339,0.000403,0.000473,0.000562,0.000624,0.000653,0.000804,0.000881,0.001084,
0.001189,0.001288,0.001429,0.001603,0.001758,0.001862,0.002018,0.002265,0.002427,0.00263,0.002917,0.003199,
0.003508,0.003846,0.004217,0.004519,0.004898,0.00537,0.005957,0.006383,0.007161,0.007674,0.008318,0.009016,
0.00955,0.010351,0.01122,0.012303,0.01349,0.014791,0.015849,0.017179,0.019055,0.020654,0.022909,0.024831,
0.027227,0.029174,0.031989,0.034674,0.038019,0.04217,0.045709,0.050119,0.054325,0.058884,0.063826,0.069984,
0.075858,0.083176,0.090157,0.096605,0.108393,0.116145,0.125893,0.139637,0.151356,0.165959,0.179887,0.194984,
0.213796,0.234423,0.254097,0.275423,0.298538,0.327341,0.363078,0.389045,0.42658,0.462381,0.506991,0.555904,
0.60256,0.668344,0.724436,0.776247,0.851138,0.933254,1 

opcode TX_env2, k, iiiiii
; AR=attackRate (0-31), D1R=decay1Rate(0-31), D1L=decay1Level(0-16), D2R=decay2Rate(0-31), RR=releaseRate(0-16)
iAR,iD1R,iD1L,iD2R,iRR,iId xin
	iAR  table iAR,  giAR
	iD1R table iD1R, giD1R
	iD1L table iD1L, giD1L
	iD2R table iD2R, giD2R
	iRR  table iRR,  giRR

	iAR /= 96000
	iD1R /= 96000
	iD2R /= 96000
	iRR /= 96000
	kRR = iRR
	printf "iAR: %f iD1R: %f iD1L: %f iD2R: %f iRR: %f \n", 1, iAR, iD1R, iD1L, iD2R, iRR
	
	xtratim iRR
	kRel release
	
	kEnv init 0
	kSta init 0   ; env started
	
	kAdd transeg 0, 0.01, -8 ,1
	; kCount timeinstk
	; printf "%d) kSta: %d, kEnv: %f, iD1R: %f, kAdd:%f \n", metro(20), iId, kSta, kEnv, iD1R, kAdd
	
	if kRel > 0 then
			kEnv -= 1/(kRR*kr)
			kEnv limit kEnv, 0, 1
			kgoto Out
	endif
	iAttDelta = 1/(iAR*kr)
	print iAttDelta
	if kSta == 0 then
		; attack, until env reaches 1
		kEnv += iAttDelta ; 1/(iAR*kr)
		kEnv limit kEnv, 0, 1
		kSta = kEnv >= 1 ? 1 : 0
		kgoto Out
	endif
	if kSta == 1 then
		if iD1R >= 0 then
			kEnv -= (1/(iD1R*kr))
			kEnv limit kEnv, iD1L, 1
			if kEnv > iD1L kgoto Out
		endif
		kSta = 2
	endif
	if kSta == 2 && iD2R >= 0 then
		kEnv -= 1/(iD2R*kr)
		kEnv limit kEnv, 0, iD1L
	endif
Out:
	kout = kEnv^6.6*kAdd  
	printf "env id=%d, kout=%f \n", metro(10), iId, kout
	xout kout
endop


opcode TX_envelope, k, iiiiii
	iAR,iD1R,iD1L,iD2R,iRR,iId xin
	iAR  table iAR,  giAR
	iD1R table iD1R, giD1R
	iD1L table iD1L, giD1L
	iD2R table iD2R, giD2R
	iRR  table iRR,  giRR

	iAR /= 96000
	iD1R /= 96000
	iD2R /= 96000
	iRR /= 96000
	kRR = iRR
	printf "iAR: %f iD1R: %f iD1L: %f iD2R: %f iRR: %f \n", 1, iAR, iD1R, iD1L, iD2R, iRR
	
	xtratim iRR
	kRel release
	
	kEnv init 0
	kSta init 0   ; env started
	
	kAdd transeg 0, 0.01, -8 ,1
	; kCount timeinstk
	; printf "%d) kSta: %d, kEnv: %f, iD1R: %f, kAdd:%f \n", metro(20), iId, kSta, kEnv, iD1R, kAdd
	
	if kRel > 0 kgoto Release
	if kSta != 0 kgoto Next
	kEnv += 1/(iAR*kr)
	kEnv limit kEnv, 0, 1
	if kEnv != 1 goto Out
	kSta = 1
Next:
	if kSta != 1 kgoto Next2
	if iD1R >= 0 goto Next1
	goto Out
Next1:
			kEnv -= (1/(iD1R*kr))
			kEnv limit kEnv, iD1L, 1
			if kEnv !=  iD1L goto Out
					kSta = 2
Next2:
			if iD2R >= 0 goto Next3
					goto Out
Next3:
			kEnv -= 1/(iD2R*kr)
			kEnv limit kEnv, 0, iD1L
			goto Out
Release:
			kEnv -= 1/(kRR*kr)
			kEnv limit kEnv, 0, 1
Out:
			xout kEnv^6.6*kAdd;5.9				
endop

;LP filter 
opcode TX_LP, a, a
	setksmps 1
	aL xin 
	aD0 init 0
	aD1 init 0

	iA1 = -0.5100490981424427
	iB0 = 1
	iB1 = 1

	aD2=aD1   ; aL[-2]
	aD1=aD0   ; aL[-1]
	aD0=aL-aD1*iA1
	aout=aD0*iB0+aD1*iB1
	// out = (in0 - in1 * a1) * b0 + in1 * b1
	
	xout aout*0.24497545092877862
endop
; HP filter
opcode TX_HP, a, a
	setksmps 1
	aL xin 
	aD0 init 0
	aD1 init 0

	iA1 = -0.99869495948492626
	iB0 = 1
	iB1 = -1

	aD2=aD1
	aD1=aD0
	aD0=aL-aD1*iA1
	aout=aD0*iB0+aD1*iB1
	
	xout aout*0.99934747974246307
endop


instr 1   ; TABLE CONSTRUCTOR
	kndx init 0
loopstart:
	if kndx = 4096 kgoto End
	; TABLES W1 - W4 
	ksin tab kndx, 1
	tabw ksin*ksin*signum(ksin), kndx, 2   ; W2
	ksinP limit ksin, 0, 1
	ksin2P limit ksin*ksin*signum(ksin),0,1
	tabw ksinP, kndx, 3 ; W3
	tabw ksin2P, kndx, 4 ; W4
	
	; TABLES W5 - W8
	kndx2 limit kndx*2, 0, 4096
	ksin2 tab kndx2, 1
	tabw ksin2,kndx, 5 ; W5
	tabw ksin2*ksin2*signum(ksin2), kndx,6 ; W6
	tabw abs(ksin2),kndx,7 ; W7 
	tabw abs(ksin2*ksin2*signum(ksin2)), kndx, 8 ; W8
	kndx += 1
	kgoto loopstart
	End:
	turnoff
endin

opcode TX_OP, a, akiiiiiiiii
	; setksmps 1
	; iKVS - veloc sensivity level 0...7
	; i1 = iAR, i2 = iD1R, i3 = iD1L, i4 = iD2R, i5 = iRR
	aMod, kCarFreq, i1, i2, i3, i4, i5, iWave, iKVS, iVel, iId xin
	iVelSen tablei iVel, 20+iKVS
	
	aCarFreq = a(kCarFreq)
	
	kEnv TX_env2 i1, i2, i3, i4, i5, iId
	
	
	; kEnv linsegr 0, 0.1, 0.1, 0.1, 0
	; xout oscili(a(kEnv), 150*iId)
	
	aPhase phasor aCarFreq
	aCar tablei aPhase+aMod, iWave, 1, 0, 1

	; iVelSen tablei giVel, 20+iKVS   
	; xout aCar * iVelSen
	; xout aCar * kEnv * iVelSen
	
	aout = aCar * interp(kEnv) * iVelSen
	; printf "TX_OP %d: kEnv: %f kRms: %f\n", metro(10), iId, kEnv, rms(aout)
	print iVelSen
	; xout aout
	xout a(kEnv)
endop


instr 4 ; MASTER
	aOP4 init 0
	seed 0
	i1 random 0.520, 0.535
	i2 random 0.420, 0.450
	i3 random 0.520, 0.535
	i4 random 0.89, 1.01
	
	kIM1 init i1  ; mod. index OP2
	kIM2 init i2  ; mod. index OP3
	kIM3 init i3  ; mod. index OP4
	k4FB init i4; fdbk 4 OP
	
	print i1
	print i2 
	print i3
	print i4
	;kIM1 init 0.47;Index Modulations 2 op  0.5    74
	;kIM2 init 0.42;Index Modulations 3 op  .42    71
	;kIM3 init 0.5;Index Modulations 4 op  .45    79
	
	kALG[][] init 13, 10  ; ALGORITHMIC MATRIX CONNECTIONS
	kALG fillarray		1,0,0,1,0,1,0, 0,0,0,
								 	1,0,0,1,1,0,0, 0,0,0,
								 	1,0,1,1,0,0,0, 0,0,0,
								 	1,1,0,0,0,1,0, 0,0,0,
								 	1,0,0,0,0,1,0, 0,1,0,
								 	0,0,1,0,1,1,0, 1,1,0,
								 	0,0,0,0,0,1,0, 1,1,0,
								 	0,0,0,0,0,0,0, 1,1,1,
								 	1,0,0,0,0,0,0, 0,0,0, 		;	only OP2 -> OP1
								 	0,0,0,0,0,0,0, 0,0,0,  	; only OP1
								 	1,0,0,0,1,0,0, 0,0,0,  	; OP4 -> OP2 -> OP1
								 	1,0,0,0,1,0,1, 0,0,0,  	; FD(OP4) -> OP2 -> OP1
								 	1,0,0,1,1,0,1, 0,0,0  		; LATELY
	
	
	; kAlgIdx = 4 ; ALG NO 0...12
	iAlgIdx = 4
	
	; knote = p4
	ifreq cpsmidi
	inote ftom ifreq
	knote = inote
	; print inote
	; === pitch foldover
	; XX: this seems to be a means to foldover midi values which lie outside
	; the range 12-108, but is not working really. Just limit the range 
	knote limit knote, 12, 108
	; knote table knote, giNOTE
	
	;==== /pitch foldover =====
	kfreq mtof knote
	; kfreq = cpsmidinn(knote)
	
	;==== velocity ============
	; uncomment for MIDI
	; giVel veloc 
	iVel veloc   ; XX: velocity of current midi event
	
	; giVel = p5 ; comment for MIDI in
	;=====/velocity============
	
	kOut table 99, giVOL ; OP output level 0..99
	
	printf "vel: %d, kOut: %f \n", 1, iVel, kOut
	
	
	; ===4 OP ====== 
	; OP parameters:
	; mod in, car freq X, att, D1 rel, D1 lev, D2 rel, rel, Wave,KVS
	aOP1 init 0
	
	ain4 = aOP4*kALG[iAlgIdx][6]*k4FB
	
	; iKVS points to the velocity -> amplitude table defined in the include file
	;           aMod, kCarFreq, i1, i2, i3,i4,i5, iWave, iKVS, iVel xin
	aOP4 TX_OP ain4, .5*kfreq, 31, 0, 0, 0, 15, 1,     3,    iVel, 1
	aOP4 = aOP4*kIM3
	
	ain3 = aOP4*kALG[iAlgIdx][5]
	;           aMod, kCarFreq,      i1, i2, i3,i4,i5,iWave, iKVS, iVel xin
	aOP3 TX_OP ain3, .5*kfreq*0.996,31, 17, 0, 0, 8, 5,     1,    iVel, 2  ;0.996
	aOP3 = aOP3*kIM2
	   
	ain2 = aOP3*kALG[iAlgIdx][3] + aOP4*kALG[iAlgIdx][4] 
	;           aMod, kCarFreq, i1, i2, i3,i4,i5,iWave, iKVS, iVel xin
	aOP2 TX_OP ain2, kfreq/4,  31,  9, 0, 0, 8, 1,     1,    iVel, 3
	aOP2 = kIM1*aOP2
	
	ain1 = aOP2*kALG[iAlgIdx][0] + aOP3*kALG[iAlgIdx][1] + aOP4*kALG[iAlgIdx][2]
	;           aMod, kCarFreq, i1, i2, i3,i4,i5, iWave, iKVS, iVel xin
	aOP1 TX_OP ain1, kfreq/4,  31, 9,  0,  0, 8, 1,     1,    iVel, 4
	
	; === MIXER =====
	a0 = aOP1 + aOP2*kALG[iAlgIdx][7] + aOP3*kALG[iAlgIdx][8] + aOP4*kALG[iAlgIdx][9]
	
	; === DAC =======
	a2 TX_HP a0
	a3 TX_LP a2
	
	; out  a3*kOut  ; kout table 99
	out aOP4
endin


</CsInstruments>
<CsScore>
#include "KVStab_190119.tx" ; keyboard velocity sensivity table

i1 0 0.1 ; TABLE CONSTRUCTOR INSTR

; i4 1 2  47  61
; i4 + .  36  89 
; i4 + .  48  100
; i4 + .  60  . 
; i4 + .  72  .
; i4 + .  84  .
; i4 + .  96  .
; i4 + .  108 .
e
</CsScore>
</CsoundSynthesizer>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>0</y>
 <width>0</width>
 <height>0</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
