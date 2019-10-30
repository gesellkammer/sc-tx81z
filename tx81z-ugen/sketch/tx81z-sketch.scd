Elib.midi_init;



( // init
Buffer.freeAll;
fork {
	var tablen = 4096;
	var tab1 = tablen.collect{|i| sin(i/tablen * 2pi) };
	// tabw ksin*ksin*signum(ksin), kndx, 2   ; W2
	var tab2 = tablen.collect{|i|
		var ksin = tab1[i];
		ksin * ksin * ksin.sign };
	/*  ksinP limit ksin, 0, 1
	ksin2P limit ksin*ksin*signum(ksin),0,1
	tabw ksinP, kndx, 3 ; W3
	tabw ksin2P, kndx, 4 ; W4
	*/
	var tab3 = tablen.collect{|i|
		var ksin = tab1[i];
		ksin.clip(0, 1) };
	var tab4 = tablen.collect{|i|
		var ksin = tab1[i];
		(ksin*ksin*ksin.sign).clip(0, 1) };
	var tab5 = tablen.collect{|i|
		var kndx2 = (i*2).clip(0, tablen-1);
		var ksin2 = tab1[kndx2];
		ksin2 };

	var tab6 = tablen.collect{|i|
		var ksin2 = tab5[i];
		ksin2 * ksin2 * ksin2.sign };

	var tab7 = tablen.collect{|i|
		var ksin2 = tab5[i];
		ksin2.abs };

	var tab8 = tablen.collect{|i|
		var ksin2 = tab5[i];
		abs(ksin2*ksin2*ksin2.sign) };

	~wavetables = [
		Buffer.sendCollection(s, tab1), // W1
		Buffer.sendCollection(s, tab2),
		Buffer.sendCollection(s, tab3),
		Buffer.sendCollection(s, tab4),
		Buffer.sendCollection(s, tab5),
		Buffer.sendCollection(s, tab6),
		Buffer.sendCollection(s, tab7),
		Buffer.sendCollection(s, tab8)  // W8
	];

	/*
	giAR ftgen 9, 0, 32, -2, 0,647829,452377,322874,225473,160445,112801,80602,56434,40244,28328,
	20297,14152,10306,7237,5231,3687,2601,1765,1417,1000,822,572,440,400,380,310,278,165,135,130,125
	*/
	~table_AR = Buffer.sendCollection(s, [
		0, 647829, 452377, 322874, 225473,
		160445, 112801, 80602, 56434, 40244,
		28328, 20297, 14152, 10306, 7237,
		5231, 3687, 2601, 1765, 1417,
		1000, 822, 572, 440, 400,
		380, 310, 278, 165, 135,
		130,125 ]);
	~table_D1R = Buffer.sendCollection(s, [
		-1000, 3116605/*0*/, 2179104/*1*/, 1547622/*2*/, 1086731/*3*/,
		778176/*4*/, 542607/*5*/, 389089/*6*/, 272208/*7*/, 450000 /*316000 8*/,
		137953/*9*/, 98004/*10*/, 69000/*11*/, 48235/*12*/, 34239/*13*/,
		24524/*14*/, 36000 /*17512 15*/, 27000 /*12895 16*/, 13859 /*17*/, 8843,
		5774, 4387, 3254, 2040, 1573,
		955, 925, 575, 475, 200,
		125, 1 ]);
	~table_D2R = Buffer.sendCollection(s, [
		-1000, 3101310, 2168831, 1551896, 1084546,
		771475, 541448, 387275, 270054, 192173,
		134025, 96252, 67545, 47431, 34174,
		24459, 17359, 11987, 8775, 6000,
		4302, 2885, 2136, 1415, 1000,
		700, 677, 355, 331, 254,
		1, 1 ]);
	~table_RR = Buffer.sendCollection(s, [
		0, 1559542, 779813, 386094, 192749,
		97322, 48481, 24041, 11808, 6038,
		2957, 1570, 858, 350, 118,
		1]);
	~table_D1L = Buffer.sendCollection(s, [
		0, 0.007943, 0.01122, 0.015849, 0.022387,
		0.031623, 0.044668, 0.063096, 0.089125, 0.125893,
		0.177828, 0.251189, 0.358922, 0.506991, 0.716143,
		1 ]);
	// vol(0..99) to amp (0..1)
	~table_VOL = Buffer.sendCollection(s, [
		0.000254, 0.000254, 0.000254, 0.000254, 0.000254,  // 0
		0.000254, 0.000254, 0.000254, 0.000254, 0.000254,  // 5
		0.000254, 0.000254, 0.000339, 0.000403, 0.000473,  // 10
		0.000562, 0.000624, 0.000653, 0.000804, 0.000881,
		0.001084, 0.001189, 0.001288, 0.001429, 0.001603,  // 20
		0.001758, 0.001862, 0.002018, 0.002265, 0.002427,
		0.00263,  0.002917, 0.003199, 0.003508, 0.003846,  // 30
		0.004217, 0.004519, 0.004898, 0.00537,  0.005957,
		0.006383, 0.007161, 0.007674, 0.008318, 0.009016,  // 40
		0.00955,  0.010351, 0.01122,  0.012303, 0.01349,
		0.014791, 0.015849, 0.017179, 0.019055, 0.020654,  // 50
		0.022909, 0.024831, 0.027227, 0.029174, 0.031989,
		0.034674, 0.038019, 0.04217,  0.045709, 0.050119,  // 60
		0.054325, 0.058884, 0.063826, 0.069984, 0.075858,
		0.083176, 0.090157, 0.096605, 0.108393, 0.116145,  // 70
		0.125893, 0.139637, 0.151356, 0.165959, 0.179887,
		0.194984, 0.213796, 0.234423, 0.254097, 0.275423,  // 80
		0.298538, 0.327341, 0.363078, 0.389045, 0.42658,
		0.462381, 0.506991, 0.555904, 0.60256,  0.668344,  // 90
		0.724436, 0.776247, 0.851138, 0.933254, 1,
		1,        1,        1,        1,        1,         // 100
	]);

	~velocity_curves = [
		Buffer.sendCollection(s, Array.fill(128, 1)),
		Buffer.sendCollection(s, [
			0,     0.22, 0.25, 0.25, 0.25, 0.25, 0.285, 0.285, 0.285, 0.285,
			0.285, 0.3,  0.3,  0.3,  0.3,  0.3,  0.34,  0.34,  0.34,  0.34,
			0.34,  0.36, 0.36, 0.36, 0.36, 0.36, 0.36,  0.39,  0.39,  0.39,
			0.39,  0.39, 0.39, 0.39, 0.39, 0.39, 0.39,  0.39,  0.39,  0.39,
			0.39,  0.39, 0.43, 0.43, 0.43, 0.43, 0.43,  0.43,  0.43,  0.43,
			0.43,  0.43, 0.47, 0.47, 0.47, 0.47, 0.47,  0.47,  0.47,  0.47,
			0.47,  0.47, 0.47, 0.47, 0.47, 0.47, 0.47,  0.47,  0.47,  0.47,
			0.47,  0.47, 0.5,  0.5,  0.5,  0.5,  0.5,   0.5,   0.5,   0.5,
			0.5,   0.5,  0.5,  0.5,  0.5,  0.55, 0.55,  0.55,  0.55,  0.55,
			0.55,  0.55, 0.55, 0.55, 0.55, 0.55, 0.55,  0.55,  0.55,  0.55,
			0.55,  0.55, 0.55, 0.55, 0.55, 0.55, 0.55,  0.55,  0.55,  0.55,
			0.55,  0.6,  0.6,  0.6,  0.6,  0.6,  0.6,   0.6,   0.6,   0.6,
			0.6,   0.6,  0.6,  0.6,  0.6,  0.6,  0.6,   0.6]),
		Buffer.sendCollection(s, [
			0,     0.032, 0.032, 0.032, 0.055, 0.055, 0.055, 0.055, 0.075, 0.075,
			0.075, 0.075, 0.075, 0.1,   0.1,   0.1,   0.1,   0.1,   0.117, 0.117,
			0.117, 0.117, 0.117, 0.14,  0.14,  0.14,  0.14,  0.14,  0.165, 0.165,
			0.165, 0.165, 0.165, 0.18,  0.18,  0.18,  0.18,  0.18,  0.21,  0.21,
			0.21,  0.21,  0.21,  0.23,  0.23,  0.23,  0.23,  0.23,  0.26,  0.26,
			0.26,  0.26,  0.26,  0.28,  0.28,  0.28,  0.28,  0.28,  0.3,   0.3,
			0.3,   0.3,   0.3,   0.33,  0.33,  0.33,  0.33,  0.33,  0.36,  0.36,
			0.36,  0.36,  0.36,  0.4,   0.4,   0.4,   0.4,   0.4,   0.435, 0.435,
			0.435, 0.435, 0.435, 0.46,  0.46,  0.46,  0.46,  0.46,  0.46,  0.46,
			0.46,  0.5,   0.5,   0.5,   0.5,   0.5,   0.5,   0.5,   0.55,  0.55,
			0.55,  0.55,  0.55,  0.55,  0.55,  0.55,  0.61,  0.61,  0.61,  0.61,
			0.61,  0.61,  0.61,  0.61,  0.61,  0.61,  0.66,  0.66,  0.66,  0.66,
			0.66,  0.66,  0.66,  0.72,  0.72,  0.72,  0.72,  0.72])
	];

	// alg 0-12 incl.
	~algorithms = [
		[ 1,0,0,1,0,1,0, 0,0,0 ],
		[ 1,0,0,1,1,0,0, 0,0,0 ],
		[ 1,0,1,1,0,0,0, 0,0,0 ],
		[ 1,1,0,0,0,1,0, 0,0,0 ],
		[ 1,0,0,0,0,1,0, 0,1,0 ],
		[ 0,0,1,0,1,1,0, 1,1,0 ],
		[ 0,0,0,0,0,1,0, 1,1,0 ],
		[ 0,0,0,0,0,0,0, 1,1,1 ],
		[ 1,0,0,0,0,0,0, 0,0,0 ], // 		;	only OP2 -> OP1
		[ 0,0,0,0,0,0,0, 0,0,0 ], //  	; only OP1
		[ 1,0,0,0,1,0,0, 0,0,0 ], // 	; OP4 -> OP2 -> OP1
		[ 1,0,0,0,1,0,1, 0,0,0 ], //  	; FD(OP4) -> OP2 -> OP1
		[ 1,0,0,1,1,0,1, 0,0,0 ]
	];
	~algorithms_numcols = ~algorithms[0].size;
	~algorithms_buf = Buffer.sendCollection(s, ~algorithms.flat);


	~tx_env = {|gate, ar, d1r, d1l, d2r, rr, id=0|
		var att = BufRd.kr(1, ~table_AR.bufnum, ar) / 96000;
		var dec1 = BufRd.kr(1, ~table_D1R.bufnum, d1r) / 96000;
		var sust1 = BufRd.kr(1, ~table_D1L.bufnum, d1l) / 96000;
		var dec2 = BufRd.kr(1, ~table_D2R.bufnum, d2r) / 96000;
		var rel = BufRd.kr(1, ~table_RR.bufnum, rr) / 96000;
		var env_no_decs = EnvGen.kr(Env([0, 1, 0], [att, rel], releaseNode:1), gate:gate);
		var env_no_dec2 = EnvGen.kr(Env([0, 1, sust1, 0], [att, dec1, rel], releaseNode:2), gate:gate);
		var env_no_dec1 = EnvGen.kr(Env([0, 1, 0.001, 0], [att, dec2, rel], releaseNode:2), gate:gate);
		var env_full = EnvGen.kr(Env([0, 1, sust1, 0.001, 0], [att, dec1, dec2, rel], releaseNode:3), gate:gate);
		var no_dec1 = dec1 < 0;
		var no_dec2 = dec2 < 0;
		var which = no_dec2 + (no_dec1*2);
		// 0: full, 1=no_dec2, 2=no_dec1, 3=no_dec2 && no_dec1;
		var gen = Select.kr(which,[env_full, env_no_dec2, env_no_dec1, env_no_decs]);
		// kAdd transeg 0, 0.01, -8 ,1
		var kAdd = EnvGen.ar(Env([0, 1], times:[0.01], curve:-8));
		var kout = (gen ** 6.6) * kAdd;
		kout;
	};

	~tx_lp = {|in|
		(OneZero.ar(in, 0.510049) * 0.0512) + (LPZ2.ar(in) * 0.682)
	};

	~tx_hp = {|in|
		HPF.ar(in, 10)
	};

	// -----------------------------------------------------------------
	s.sync;
	0.2.wait;

	~velcurveBufnums = Buffer.sendCollection(s, ~velocity_curves.collect{|buf| buf.bufnum});
	~waveformBufnums = Buffer.sendCollection(s, ~wavetables.collect{|buf| buf.bufnum});

	// -----------------------------------------------------------------
	s.sync;
	0.2.wait;

	~tx_op = {|gate, aMod, kCarFreq, vel, kWaveBuf, att=31, dec=16, sust=3, dec2=7, rel=16,
		       velocityCurveBuf=1, gain=1, id=0|
		// iVelSen tablei iVel, 20+iKVS
		// var velocityCurveBuf = BufRd.kr(1, ~velcurves.bufnum, iKVS, interpolation:1, loop:0);
		var iVelSen = BufRd.kr(1, velocityCurveBuf, vel, interpolation:2, loop:0);
		var aCarFreq = K2A.ar(kCarFreq);
		// kEnv TX_env2 i1, i2, i3, i4, i5, iId
		var aEnv = ~tx_env.(gate, att, dec, sust, dec2, rel, id:id);
		// aPhase phasor aCarFreq
		var aPhase = Phasor.ar(0, rate:aCarFreq/SampleRate.ir);
		// aCar tablei aPhase+aMod, iWave, 1, 0, 1
		var aCar = BufRd.ar(1, kWaveBuf, (aPhase+aMod) * tablen, interpolation:2, loop:1);
		// aout = aCar * interp(kEnv) * iVelSen
		var aOut = aCar * aEnv * (iVelSen * gain);
		aOut;
	};

	~getmtx = {|row, col|
		var val = BufRd.kr(1, ~algorithms_buf.bufnum, row * ~algorithms_numcols + col);
		val;
	};

	~tx81 = {|gate, iVel, kfreq1, kfreq2, kfreq3, kfreq4, kVol=99, velocityCurve=2,
		kIM1=0.52, kIM2=0.42, kIM3=0.52, k4FB=0.89, algIdx=5,
		iAtt4=31, iDec4=16, iSust4=3, iDecB4=7, iRel4=16, iWave4=3,
		iAtt3=31, iDec3=17, iSust3=3, iDecB3=0, iRel3=8,  iWave3=0,
		iAtt2=31, iDec2=9,  iSust2=0, iDecB2=0, iRel2=8,  iWave2=0,
		iAtt1=31, iDec1=9,  iSust1=0, iDecB1=0, iRel1=8,  iWave1=0|
		var kOut = BufRd.kr(1, ~table_VOL.bufnum, kVol);
		var algbuf = ~algorithms_buf.bufnum;
		var algnumcols = ~algorithms_numcols;
		var waveformBufnums = ~waveformBufnums.bufnum;

		var kWaveBuf4 = BufRd.kr(1, waveformBufnums, iWave4);
		var kWaveBuf3 = BufRd.kr(1, waveformBufnums, iWave3);
		var kWaveBuf2 = BufRd.kr(1, waveformBufnums, iWave2);
		var kWaveBuf1 = BufRd.kr(1, waveformBufnums, iWave1);

		var velcurveBuf = BufRd.kr(1, ~velcurveBufnums.bufnum, velocityCurve, interpolation:1, loop:0);
		var fback = LocalIn.ar(4);

		var aOP1, aOP2, aOP3, aOP4, ain4, ain3, ain2, ain1, a0, coef;

		//ain4 = aOP4*kALG[algIdx][6]*k4FB
		aOP4 = fback[3];
		// ain4 = aOP4 * BufRd.kr(1, algbuf, algIdx*algnumcols + 6) * k4FB;
		ain4 = aOP4 * ~getmtx.(algIdx, 6) * k4FB;

		// aOP4 TX_OP ain4, .5*kfreq, 31, 16, 3, 7, 16, 1,     3,    iVel, 1
		aOP4 = ~tx_op.(gate, ain4, kfreq4, iVel, kWaveBuf4, iAtt4, iDec4, iSust4, iDecB4, iRel4, velcurveBuf, id:4);
		aOP4 = aOP4*kIM3;

		// ain3 = aOP4 * kALG[algIdx][5]
		ain3 = aOP4 * BufRd.kr(1, algbuf, algIdx*algnumcols + 5);

		// aOP3 TX_OP ain3, .5*kfreq*0.996,31, 17, 0, 0, 8, 5,     1,    iVel, 2  ;0.996
		aOP3 = ~tx_op.(gate, ain3, kfreq3, iVel, kWaveBuf3, iAtt3, iDec3, iSust3, iDecB3, iRel3, velcurveBuf);
		aOP3 = aOP3 * kIM2;

		// ain2 = aOP3*kALG[algIdx][3] + aOP4*kALG[algIdx][4]
		// ain2 = aOP3 * BufRd.kr(1, algbuf, algIdx*algnumcols + 3) + aOP4 * BufRd.kr(1, algbuf, iAlgUdx*algnbumcols+4);
		ain2 = (aOP3 * ~getmtx.(algIdx, 3)) + (aOP4 * ~getmtx.(algIdx, 4));
		// aOP2 TX_OP ain2, kfreq/4,  31,  9, 0, 0, 8, 1,     1,    iVel, 3
		aOP2 = ~tx_op.(gate, ain2, kfreq2, iVel, kWaveBuf2, iAtt2, iDec2, iSust2, iDecB2, iRel2, velcurveBuf);
		aOP2 = kIM1 * aOP2;

		// ain1 = aOP2*kALG[algIdx][0] + aOP3*kALG[algIdx][1] + aOP4*kALG[algIdx][2]
		ain1 = (aOP2 * ~getmtx.(algIdx, 0)) + (aOP3 * ~getmtx.(algIdx, 1)) + (aOP4 * ~getmtx.(algIdx, 2));
		// aOP1 TX_OP ain1, kfreq/4,  31, 9,  0,  0, 8, 1,     1,    iVel, 4
		aOP1 = ~tx_op.(gate, ain1, kfreq1, iVel, kWaveBuf1, iAtt1, iDec1, iSust1, iDecB1, iRel1, velcurveBuf);
		// a0 = aOP1 + aOP2*kALG[algIdx][7] + aOP3*kALG[algIdx][8] + aOP4*kALG[algIdx][9]
		a0 = aOP1 + (aOP2 * ~getmtx.(algIdx, 7)) + (aOP3 * ~getmtx.(algIdx, 8)) + (aOP4 * ~getmtx.(algIdx, 9));

		LocalOut.ar([aOP1, aOP2, aOP3, aOP4]);

		a0 = ~tx_lp.(a0);
		a0 = ~tx_hp.(a0);
		a0 = a0 * kOut;
		a0;

	};

	s.sync; // --------------------------------------------------------------------

	SynthDef(\tx_demo, {|gate=1, kfreq=220, vel=90, algIdx=0|
		var tx = ~tx81.(gate, iVel:vel, algIdx:algIdx,
			kfreq1:kfreq/2, kfreq2:kfreq/2*1.02, kfreq3:kfreq*0.996, kfreq4:kfreq,
			k4FB:0.91, iWave4:0, kIM1:0.6, kIM2: 0.52, kIM3:0.6);
		var env = EnvGen.ar(Env.asr(0, 1, 0.005), gate:gate, doneAction:Done.freeSelf);
		tx = tx * env;
		Out.ar(0, tx);
	}).send;

	s.sync;	"ready!".postln;
}
)

(
~synths = Array.fill(128, nil);
MIDIFunc.noteOn({|vel, midinote|
	~synths[midinote] = Synth(\tx_demo, args:[kfreq:midinote.midicps, vel:vel, algIdx:10]);
});

MIDIFunc.noteOff({|vel, midinote|
	~synths[midinote].set(\gate, 0);
});

)

5.rand