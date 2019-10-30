Elib.midi_init;

(
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

	~waves =[tab1, tab2, tab3, tab4, tab5, tab6, tab7, tab8];

	0.1.wait;

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

	s.sync; // ----------------------------------------------------------------------
	~waveformBufnums = Buffer.sendCollection(s, ~wavetables.collect{|buf| buf.bufnum});

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

	~tx_env = {|gate, att, dec, sust, dec2, sust2=0, rel=0.1, id=0|
		var env = EnvGen.ar(
			Env([0, 1, sust, sust2, 0], [att, dec, dec2, rel], releaseNode: 3),
			gate: gate);
		env.poll(label:id);
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

	~tx_op = {|gate, aMod, kCarFreq, amp, kWaveBuf, att=0.01, dec=0.01, sust=0.2, dec2=0.2, sust2=0, rel=0.05, id=0|
		var aCarFreq = K2A.ar(kCarFreq);
		// kEnv TX_env2 i1, i2, i3, i4, i5, iId
		var aEnv = ~tx_env.(gate, att, dec, sust, dec2, rel, id:id);
		// aPhase phasor aCarFreq
		var aPhase = Phasor.ar(0, rate:aCarFreq/SampleRate.ir);
		// aCar tablei aPhase+aMod, iWave, 1, 0, 1
		var aCar = BufRd.ar(1, kWaveBuf, (aPhase+aMod)*4096, interpolation:2, loop:1);
		// aout = aCar * interp(kEnv) * iVelSen
		var aOut = aCar * aEnv * amp;
		aOut;
	};

	~getmtx = {|row, col|
		var val = BufRd.kr(1, ~algorithms_buf.bufnum, row * ~algorithms_numcols + col);
		val;
	};

	~tx81 = {|gate, amp=1, kfreq1, kfreq2, kfreq3, kfreq4,
		kIM1=0.52, kIM2=0.42, kIM3=0.52, k4FB=0.89, algIdx=3,
		att1=0.001, dec1=0.4, sust1=0.0, decB1=0.01, sustB1=0.0, iWave1=0,
		att2=0.001, dec2=0.4, sust2=0.0, decB2=0.01, sustB2=0.0, iWave2=0,
		att3=0.001, dec3=0.2, sust3=0.0, decB3=0.01, sustB3=0.0, iWave3=0,
		att4=0.001, dec4=0.4, sust4=0.3, decB4=2.00, sustB4=0.3, iWave4=0|
		var rel = 0.05;
		var algbuf = ~algorithms_buf.bufnum;
		var algnumcols = ~algorithms_numcols;
		var waveformBufnums = ~waveformBufnums.bufnum;

		var kWaveBuf4 = BufRd.kr(1, waveformBufnums, iWave4);
		var kWaveBuf3 = BufRd.kr(1, waveformBufnums, iWave3);
		var kWaveBuf2 = BufRd.kr(1, waveformBufnums, iWave2);
		var kWaveBuf1 = BufRd.kr(1, waveformBufnums, iWave1);

		var fback = LocalIn.ar(4);

		var aOP1, aOP2, aOP3, aOP4, ain4, ain3, ain2, ain1, a0, coef;

		aOP4 = fback[3];
		RMS.kr(aOP4).ampdb.poll(label:"aOP4-fback");

		// ain4 = aOP4 * BufRd.kr(1, algbuf, algIdx*algnumcols + 6) * k4FB;
		ain4 = aOP4 * (~getmtx.(algIdx, 6) * k4FB);

		// aOP4 TX_OP ain4, .5*kfreq, 31, 16, 3, 7, 16, 1,     3,    iVel, 1
		// gate, aMod, kCarFreq, amp, kWaveBuf, att=0.01, dec=0.01, sust=0.2, dec2=0.2, sust2=0, rel=0.05
		aOP4 = ~tx_op.(gate, aMod:ain4, kCarFreq:kfreq4, amp:amp, kWaveBuf:kWaveBuf4,
			att:att4, dec:dec4, sust:sust4, dec2:decB4, sust2: sustB4, rel:rel, id:4);
		RMS.kr(aOP4).ampdb.poll(label:"AOP4-pre");
		aOP4 = aOP4*kIM3;

		// ain3 = aOP4 * kALG[algIdx][5]
		ain3 = aOP4 * BufRd.kr(1, algbuf, algIdx*algnumcols + 5);

		// aOP3 TX_OP ain3, .5*kfreq*0.996,31, 17, 0, 0, 8, 5,     1,    iVel, 2  ;0.996
		// aOP3 = ~tx_op.(gate, ain3, kfreq3, iVel, kWaveBuf3, iAtt3, iDec3, iSust3, iDecB3, iRel3, velcurveBuf);
		aOP3 = ~tx_op.(gate, aMod:ain3, kCarFreq:kfreq3, amp:amp, kWaveBuf:kWaveBuf3,
			att:att3, dec:dec3, sust:sust3, dec2:decB3, sust2:sustB3, rel:rel);
		aOP3 = aOP3 * kIM2;

		// ain2 = aOP3*kALG[algIdx][3] + aOP4*kALG[algIdx][4]
		// ain2 = aOP3 * BufRd.kr(1, algbuf, algIdx*algnumcols + 3) + aOP4 * BufRd.kr(1, algbuf, iAlgUdx*algnbumcols+4);
		ain2 = (aOP3 * ~getmtx.(algIdx, 3)) + (aOP4 * ~getmtx.(algIdx, 4));
		// aOP2 TX_OP ain2, kfreq/4,  31,  9, 0, 0, 8, 1,     1,    iVel, 3
		// aOP2 = ~tx_op.(gate, ain2, kfreq2, iVel, kWaveBuf2, iAtt2, iDec2, iSust2, iDecB2, iRel2, velcurveBuf);
		aOP2 = ~tx_op.(gate, aMod:ain2, kCarFreq:kfreq2, amp:amp, kWaveBuf:kWaveBuf2,
			att:att2, dec:dec2, sust:sust2, dec2:decB2, sust2: sustB2, rel:rel);
		aOP2 = kIM1 * aOP2;

		// ain1 = aOP2*kALG[algIdx][0] + aOP3*kALG[algIdx][1] + aOP4*kALG[algIdx][2]
		ain1 = (aOP2 * ~getmtx.(algIdx, 0)) + (aOP3 * ~getmtx.(algIdx, 1)) + (aOP4 * ~getmtx.(algIdx, 2));
		// aOP1 TX_OP ain1, kfreq/4,  31, 9,  0,  0, 8, 1,     1,    iVel, 4
		aOP1 = ~tx_op.(gate, aMod:ain1, kCarFreq:kfreq1, amp:amp, kWaveBuf:kWaveBuf1,
			att:att1, dec:dec1, sust:sust1, dec2:decB1, sust2: sustB1, rel:rel);
		aOP1 = aOP1;
		// a0 = aOP1 + aOP2*kALG[algIdx][7] + aOP3*kALG[algIdx][8] + aOP4*kALG[algIdx][9]
		a0 = aOP1 + (aOP2 * ~getmtx.(algIdx, 7)) + (aOP3 * ~getmtx.(algIdx, 8)) + (aOP4 * ~getmtx.(algIdx, 9));

		LocalOut.ar([aOP1, aOP2, aOP3, aOP4]);

		a0 = ~tx_lp.(a0);
		a0 = ~tx_hp.(a0);

		RMS.kr(aOP1).ampdb.poll(label:"aOP1");
		RMS.kr(aOP2).ampdb.poll(label:"aOP2");
		RMS.kr(aOP3).ampdb.poll(label:"aOP3");
		RMS.kr(aOP4).ampdb.poll(label:"aOP4");
		RMS.kr(a0).ampdb.poll(label:"a0");

		a0;
		// aOP4;

	};

	s.sync; // ----------------------------------------------
	SynthDef(\tx, {|gate=1, kfreq=220, amp=10, algIdx=0, gain=1, wave1=0, wave2=0|
		var tx = ~tx81.(gate, amp:amp, algIdx:algIdx,
			kfreq1:kfreq/4, kfreq2:kfreq/4, kfreq3:0.5*kfreq*0.996, kfreq4:kfreq*0.5,
			k4FB:0.99, iWave4:3, kIM1:0.6, kIM2: 0.52, kIM3:0.6, iWave1:wave1, iWave2:wave2);
		var env = EnvGen.ar(Env.asr(0, 1, 0.005), gate:gate, doneAction:Done.freeSelf);
		tx = tx * env * gain;
		Out.ar(0, tx);
	}).send;

	s.sync; "ready 2!".postln;
};

~vel2amp = {|vel| vel/127  ** 3 };

)

a = Synth(\tx, args:[kfreq:500, amp:1, algIdx:3])


( // Perf
)
a.set(\gate, 0)



(
~synths = Array.fill(128, nil);
MIDIFunc.noteOn({|vel, midinote|
	~synths[midinote] = Synth(\tx, args:[kfreq:midinote.midicps, amp:~vel2amp.(vel), algIdx:0,
		gain:1, wave1:1, wave2:2]
	);
});

MIDIFunc.noteOff({|vel, midinote|
	~synths[midinote].set(\gate, 0);
});

)

~vel2amp.(90)*10