/*

Tx81z
=====

A Port of Csound's version of Yamaha's TX81Z four operator FM synth

Copyright by Eduardo Moguillansky (2019)

This code is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this source; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
02110-1301 USA

Usage and Documentation
=======================

See the .schelp file for info

Example
=======

(
// init data of Tx81z, connect to midi

Tx81z.initData();
MIDIClient.init;
MIDIIn.connectAll;

)

(
SynthDef(\tx81z_demo, {|gate=1, kfreq=220, vel=90, algorithm=0|
    var tx = Tx81z.ar(gate, velocity:vel, algorithm:algorithm,
        kfreq1:kfreq/2, kfreq2:kfreq/2*1.02, kfreq3:kfreq*0.996, kfreq4:kfreq,
        feedback:0.91, wave4:3, op2:0.6, op3: 0.52, op4:0.6, doneAction:2);
    Out.ar(0, tx);
}).send;

~synths = Array.fill(128, nil);

MIDIFunc.noteOn({|vel, midinote|
    ~synths[midinote] = Synth(\tx81z_demo, args:[kfreq:midinote.midicps, vel:vel, algorithm:4]);
});

MIDIFunc.noteOff({|vel, midinote|
    ~synths[midinote].set(\gate, 0);
});

)

*/

Tx81z {
    classvar
    initDone = false,
    wavetableLength = 4096,
    wavetableBufs,
    table_AR,
    table_D1R,
    table_D2R,
    table_RR,
    table_D1L,
    table_VOL,
    velocityCurves;

    classvar algorithms = #[
        [ 1,0,0,1,0,1,0, 0,0,0 ],
        [ 1,0,0,1,1,0,0, 0,0,0 ],
        [ 1,0,1,1,0,0,0, 0,0,0 ],
        [ 1,1,0,0,0,1,0, 0,0,0 ],
        [ 1,0,0,0,0,1,0, 0,1,0 ],
        [ 0,0,1,0,1,1,0, 1,1,0 ],
        [ 0,0,0,0,0,1,0, 1,1,0 ],
        [ 0,0,0,0,0,0,0, 1,1,1 ],
        [ 1,0,0,0,0,0,0, 0,0,0 ], //    ; only OP2 -> OP1
        [ 0,0,0,0,0,0,0, 0,0,0 ], //    ; only OP1
        [ 1,0,0,0,1,0,0, 0,0,0 ], //    ; OP4 -> OP2 -> OP1
        [ 1,0,0,0,1,0,1, 0,0,0 ], //    ; FD(OP4) -> OP2 -> OP1
        [ 1,0,0,1,1,0,1, 0,0,0 ]
    ];

    // OP1 is always present in the result
    classvar <algorithmColumns = #[
        "2 -> 1",
        "3 -> 1",
        "4 -> 1",
        "3 -> 2",
        "4 -> 2",
        "4 -> 3",
        "4 -> 4",
        "+2",
        "+3",
        "+4"
    ];

    classvar <algorithmDescrs = #[
        "4 -> 3 -> 2 -> 1",
        "(3 + 4) -> 2 -> 1",
        "(4 + (3->2)) -> 1",
        "(2 + (4->3)) -> 1",
        "(4->3) + (2->1)",
        "(4->1) + (4->2) + (4->3)",
        "(4->3) + 2",
        "1 + 2 + 3 + 4",
        "2 -> 1",
        "1",
        "4 -> 2 -> 1",
        "(4->4) -> 2 -> 1",
        "(4 + 3) -> 2 -> 1"
    ];

    // the algorithms matrix is flattened in the server so we need to know the row width
    classvar algorithmsNumcols = 10;    
    classvar
    algorithmsBuf,
    velcurveBufnums,
    waveformBufnums;

    *initData {
        if(initDone.not) {
            this.m_initData();
            initDone = true;
        }
    }

    *m_initData {
        fork {
            var s = Server.default;
            var tablen = wavetableLength;
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

            // Each operator can have its own wavetable (0-7)
            wavetableBufs = [
                Buffer.sendCollection(s, tab1), // W1
                Buffer.sendCollection(s, tab2),
                Buffer.sendCollection(s, tab3),
                Buffer.sendCollection(s, tab4),
                Buffer.sendCollection(s, tab5),
                Buffer.sendCollection(s, tab6),
                Buffer.sendCollection(s, tab7),
                Buffer.sendCollection(s, tab8)  // W8
            ];

            // Envelope. The envelope consists of one attack and two decay
            // segments.
            // AR = attack rate. idx 0=no attack, 1=longest attack (6.5 seconds), 31=shortest (0.001)
            // D1R = decay1. idx 0=disabled, 1=slow decay, 31=fast decay
            // D1L = sustain (level after decay). 0=disabled, 1=0.0, 15=1.0
            // D2R = decay2. idx 0=disabled, 1=slow decay, 31=fast decay
            // RR = release. idx 0=disabled, 1=longest release, 15=shortest
            table_AR = Buffer.sendCollection(s, #[
                0, 647829, 452377, 322874, 225473,
                160445, 112801, 80602, 56434, 40244,
                28328, 20297, 14152, 10306, 7237,
                5231, 3687, 2601, 1765, 1417,
                1000, 822, 572, 440, 400,
                380, 310, 278, 165, 135,
                130,125 ]);
            table_D1R = Buffer.sendCollection(s, #[
                -1000, 3116605/*0*/, 2179104/*1*/, 1547622/*2*/, 1086731/*3*/,
                778176/*4*/, 542607/*5*/, 389089/*6*/, 272208/*7*/, 450000 /*316000 8*/,
                137953/*9*/, 98004/*10*/, 69000/*11*/, 48235/*12*/, 34239/*13*/,
                24524/*14*/, 36000 /*17512 15*/, 27000 /*12895 16*/, 13859 /*17*/, 8843,
                5774, 4387, 3254, 2040, 1573,
                955, 925, 575, 475, 200,
                125, 1 ]);
            table_D2R = Buffer.sendCollection(s, #[
                -1000, 3101310, 2168831, 1551896, 1084546,
                771475, 541448, 387275, 270054, 192173,
                134025, 96252, 67545, 47431, 34174,
                24459, 17359, 11987, 8775, 6000,
                4302, 2885, 2136, 1415, 1000,
                700, 677, 355, 331, 254,
                1, 1 ]);
            table_RR = Buffer.sendCollection(s, #[
                0, 1559542, 779813, 386094, 192749,
                97322, 48481, 24041, 11808, 6038,
                2957, 1570, 858, 350, 118,
                1]);
            table_D1L = Buffer.sendCollection(s, #[
                0, 0.007943, 0.01122, 0.015849, 0.022387,
                0.031623, 0.044668, 0.063096, 0.089125, 0.125893,
                0.177828, 0.251189, 0.358922, 0.506991, 0.716143,
                1 ]);
            // table mapping a volume 0..99 to amplitude
            table_VOL = Buffer.sendCollection(s, #[
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

            // there are three velocity curves (0..2)
            // 0: no sensitivity to velocity
            // 1: some sensitivity, range from 0 to 0.6
            // 2: medium sensitivity, range from 0 to 0.72

            velocityCurves = [
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

            algorithmsBuf = Buffer.sendCollection(s, algorithms.flat);

            s.sync;

            velcurveBufnums = Buffer.sendCollection(s, velocityCurves.collect{|buf| buf.bufnum});
            waveformBufnums = Buffer.sendCollection(s, wavetableBufs.collect{|buf| buf.bufnum});

            s.sync;

        } // end fork
    } // end initData

    // generates the envelope
    * m_Env { |gate, ar, d1r, d1l, d2r, rr, id=0 |
        var att = BufRd.kr(1, table_AR.bufnum, ar) / 96000;
        var dec1 = BufRd.kr(1, table_D1R.bufnum, d1r) / 96000;
        var sust1 = BufRd.kr(1, table_D1L.bufnum, d1l) / 96000;
        var dec2 = BufRd.kr(1, table_D2R.bufnum, d2r) / 96000;
        var rel = BufRd.kr(1, table_RR.bufnum, rr) / 96000;
        var env_no_decs = EnvGen.kr(Env([0, 1, 0], [att, rel], releaseNode:1), gate:gate);
        var env_no_dec2 = EnvGen.kr(Env([0, 1, sust1, 0], [att, dec1, rel], releaseNode:2), gate:gate);
        var env_no_dec1 = EnvGen.kr(Env([0, 1, 0.0001, 0], [att, dec2, rel], releaseNode:2), gate:gate);
        var env_full = EnvGen.kr(Env([0, 1, sust1, 0.0001, 0], [att, dec1, dec2, rel], releaseNode:3), gate:gate);
        var no_dec1 = dec1 < 0;
        var no_dec2 = dec2 < 0;
        var which = no_dec2 + (no_dec1*2);
        // 0: full, 1=no_dec2, 2=no_dec1, 3=no_dec2 && no_dec1;
        var gen = Select.kr(which,[env_full, env_no_dec2, env_no_dec1, env_no_decs]);
        // kAdd transeg 0, 0.01, -8 ,1
        var kAdd = EnvGen.ar(Env([0, 1], times:[0.01], curve:-8));
        var kout = (gen ** 6.6) * kAdd;
        ^kout;
    }

    // filter very low and some high frequencies.
    * m_FilterPost {|in|
        var lo = (OneZero.ar(in, 0.510049) * 0.0512) + (LPZ2.ar(in) * 0.682);
        var out = HPF.ar(lo, 10);
        ^out;
    }

    // defines one of the 4 operators
    //   gate:the gate passed to the .ar method
    //   aMod: the modulation signal (an audio signal)
    //   kCarFreq: the carrier frequency (can be modulated, could be audio)
    //   vel: the velocity (0-127) as passed to the .ar method
    //   kWaveBuf: the bufnum containing the wavetable uses for the carrier
    //   att, dec, sust, dec2, rel: envelope
    //   velocityCurveBuf: the bufnum containing the velocity curve
    //   gain: a gain which is applied to this operator
    //   id: an id, for debugging purposes
    * m_Operator {|gate, aMod, carFreq, vel, kWaveBuf, att=31, dec=16, sust=3, dec2=7, rel=16,
        velocityCurveBuf=1, gain=1, id=0|
        // iVelSen tablei iVel, 20+iKVS
        // var velocityCurveBuf = BufRd.kr(1, ~velcurves.bufnum, iKVS, interpolation:1, loop:0);
        var iVelSen = BufRd.kr(1, velocityCurveBuf, vel, interpolation:2, loop:0);
        var aCarFreq = K2A.ar(carFreq);
        // kEnv TX_env2 i1, i2, i3, i4, i5, iId
        var aEnv = this.m_Env(gate, att, dec, sust, dec2, rel, id:id);
        // aPhase phasor aCarFreq
        var aPhase = Phasor.ar(0, rate:aCarFreq/SampleRate.ir);
        // aCar tablei aPhase+aMod, iWave, 1, 0, 1
        var aCar = BufRd.ar(1, kWaveBuf, (aPhase+aMod) * wavetableLength, interpolation:2, loop:1);
        // aout = aCar * interp(kEnv) * iVelSen
        var aOut = aCar * aEnv * (iVelSen * gain);
        ^aOut;
    }

    /*
    Args:
      gate: opens and closes the envelope.
      velocity: 0-127.
      kfreq1, kfreq2, kfreq3, kfreq4: frequencies of each operator
      volume: overall volume (0-99)
      velocityCurve: 0=no sensitivity, 1=low sensitivity, 2=medium sensitivity
      op1, op2, op3, op4: gain of each operator (op2=kIM1, op3=kIM2, op4=kIM3)
      feedback: feedback coeffiecient applied to OP4 (k4FB)
      algorithm: algorithm index (0..12)
      doneAction: what to do when the gate closes
      att_, dec_, sust_, ext_, rel_: attack, decay, sustain, extinction and release for each operator
      wave1, wave2, wave3, wave4: the wavetable used for each operator (0..7, 0 is a sinewave)

    Envelope:

    the envelope is defined by 5 parameters.

    * The sound starts at 0, raises to 1 in `att` time
    * If `sust` is not 0, env decreases to `sust` in `dec` time
    * If `ext` is not 0, env decreases to 0 in `ext` time
    * If `gate` is closed while envelope has not reached 0, it ramps down
      to 0 in `rel` time.

    */
    * ar {|gate, velocity, kfreq1, kfreq2, kfreq3, kfreq4, volume=99, velocityCurve=2,
        op1=1, op2=0.52, op3=0.42, op4=0.52, feedback=0.89, algorithm=5, doneAction=0,
        att4=31, dec4=16, sust4=3, ext4=7, rel4=15, wave4=3,
        att3=31, dec3=17, sust3=3, ext3=0, rel3=8,  wave3=0,
        att2=31, dec2=9,  sust2=0, ext2=0, rel2=8,  wave2=0,
        att1=31, dec1=9,  sust1=0, ext1=0, rel1=8,  wave1=0|
        var algIdx = algorithm;
        var kOut = BufRd.kr(1, table_VOL.bufnum, volume);
        var algbuf = algorithmsBuf.bufnum;
        var algnumcols = algorithmsNumcols;
        var waveTables = waveformBufnums.bufnum;

        var kWaveBuf4 = BufRd.kr(1, waveTables, wave4);
        var kWaveBuf3 = BufRd.kr(1, waveTables, wave3);
        var kWaveBuf2 = BufRd.kr(1, waveTables, wave2);
        var kWaveBuf1 = BufRd.kr(1, waveTables, wave1);
        var mtxcols = algorithmsNumcols;
        var algrow = algIdx * algnumcols;

        var velcurveBuf = BufRd.kr(1, velcurveBufnums.bufnum, velocityCurve, interpolation:1, loop:0);
        var fback = LocalIn.ar(4);

        var aOP1, aOP2, aOP3, aOP4, ain4, ain3, ain2, ain1, a0, coef;

        //ain4 = aOP4*kALG[algIdx][6]*k4FB
        aOP4 = fback[3];
        ain4 = aOP4 * BufRd.kr(1, algbuf, algrow + 6) * feedback;

        // aOP4 TX_OP ain4, .5*kfreq, 31, 16, 3, 7, 16, 1,     3,    iVel, 1
        aOP4 = this.m_Operator(gate, ain4, kfreq4, velocity, kWaveBuf4,
            att4, dec4, sust4, ext4, rel4, velcurveBuf, id:4);
        aOP4 = aOP4*op4;

        // ain3 = aOP4 * kALG[algIdx][5]
        ain3 = aOP4 * BufRd.kr(1, algbuf, algrow + 5);

        // aOP3 TX_OP ain3, .5*kfreq*0.996,31, 17, 0, 0, 8, 5,     1,    iVel, 2  ;0.996
        aOP3 = this.m_Operator(gate, ain3, kfreq3, velocity, kWaveBuf3,
            att3, dec3, sust3, ext3, rel3, velcurveBuf);
        aOP3 = aOP3 * op3;

        // ain2 = aOP3*kALG[algIdx][3] + aOP4*kALG[algIdx][4]
        ain2 = (
            (aOP3 * BufRd.kr(1, algbuf, algrow + 3)) +
            (aOP4 * BufRd.kr(1, algbuf, algrow + 4))
        );
        // aOP2 TX_OP ain2, kfreq/4,  31,  9, 0, 0, 8, 1,     1,    iVel, 3
        aOP2 = this.m_Operator(gate, ain2, kfreq2, velocity, kWaveBuf2,
            att2, dec2, sust2, ext2, rel2, velcurveBuf);
        aOP2 = op2 * aOP2;

        // ain1 = aOP2*kALG[algIdx][0] + aOP3*kALG[algIdx][1] + aOP4*kALG[algIdx][2]
        ain1 = (
            (aOP2 * BufRd.kr(1, algbuf, algrow + 0)) +
            (aOP3 * BufRd.kr(1, algbuf, algrow + 1)) +
            (aOP4 * BufRd.kr(1, algbuf, algrow + 2))
        );
        // aOP1 TX_OP ain1, kfreq/4,  31, 9,  0,  0, 8, 1,     1,    iVel, 4
        aOP1 = this.m_Operator(gate, ain1, kfreq1, velocity, kWaveBuf1,
            att1, dec1, sust1, ext1, rel1, velcurveBuf);
        aOP1 = op1 * aOP1;
        // a0 = aOP1 + aOP2*kALG[algIdx][7] + aOP3*kALG[algIdx][8] + aOP4*kALG[algIdx][9]
        a0 = (
            aOP1 +
            (aOP2 * BufRd.kr(1, algbuf, algrow + 7)) +
            (aOP3 * BufRd.kr(1, algbuf, algrow + 8)) +
            (aOP4 * BufRd.kr(1, algbuf, algrow + 9))
        );

        LocalOut.ar([aOP1, aOP2, aOP3, aOP4]);

        a0 = this.m_FilterPost(a0);
        a0 = a0 * EnvGen.ar(Env.asr(ControlDur.ir, 1, ControlDur.ir), gate:gate, doneAction:doneAction);
        ^(a0 * kOut);
    }
}



