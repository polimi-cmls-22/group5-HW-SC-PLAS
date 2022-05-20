(

~bufFire;
~bufFrog;
~bufStep;
~bufWolf;


if(s.hasBooted != true,{
	s.boot;
	"STARTING THE SERVER...".postln;
});
"STARTING THE SYSTEM...".postln;
s.freeAll;
s.doWhenBooted(
	{

		//VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


		var f,w1,w2,w3,w4,w5,w6,v6,i1,i2,i3,i4,meter,

		scopingSynth,image,

		background,
		// margin

		marg = 25,

		// main window dimension

		winWidth = 900,
		winHeight = 650,
		winUpDown = 80,
		winRL = 200,

		panWinRL = 10,
		panWinUpDown = 50,
		panWinWidth = 600,
		panWinHeight = 300,

		// single section dimensions

		sectWinWidth = 750-(2*marg),
		sectWinHeight = (winHeight-(5*marg))/4,

		// label
		titleWidth = 120,
		titleHeight = 20,

		//knob dimension
		knobDim = 50,
		knobIntraDist = 13,

		knobLabelWidth = knobDim,
		knobLabelHeight = 15,

		//numberbox dimension

		numBoxWidth = knobDim,
		numBoxHeight = 15,

		//WINDOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		elRadius = 17,
		xStart=1,
		yStart=1,
		height=panWinHeight,
		width=panWinWidth,
		numOfPoints =4,

		centerPosX = width/2,
		centerPosY = height,
		selPos = -1;


		/*
		*rows: 0 fire, 1 wolf, 2 frog, 3 step
		*columns: 0 pan Knob, 1 distance Knob, 2 x, 3 y, 4 image, 5 positioner
		*/
		~wpBool=false;
		~wp;
		~wpNew;
		~knobPos=Array2D.new(4,7);
		~scopefire;
		~scopewolf;
		~scopefrog;
		~scopestep;
		~colors=[Color.fromHexString("#78cdd7"),Color.white,Color.fromHexString("#78cdd7"),Color.black];
		~wolfpath;
		~path= thisProcess.nowExecutingPath.dirname;
		~srcPath = ~path +/+ "buffer/1.wav";

		// panner variables

		//WINDOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		~wolfPointer =  ~path +/+ "/pointers/wolf.png";
		~firePointer =  ~path +/+ "/pointers/fire.png";
		~cricketPointer =  ~path +/+ "/pointers/cricket.png";
		~stepsPointer =  ~path +/+ "/pointers/steps.png";
		~wolfBG = ~path +/+ "/backgrounds/Wolf_crop.png";
		~fireBG = ~path +/+ "/backgrounds/Fire_crop.png";
		~shrekBG = ~path +/+ "/backgrounds/Shrek_crop.png";
		~walkBG = ~path +/+ "/backgrounds/Walk_crop.png";
		~wolfImage = Image.new(~wolfPointer);
		~fireImage = Image.new(~firePointer);
		~stepsImage = Image.new(~stepsPointer);
		~cricketImage = Image.new(~cricketPointer);
		~knobPos[0,4]= ~fireImage;
		~knobPos[1,4]= ~wolfImage;
		~knobPos[2,4]= ~cricketImage;
		~knobPos[3,4]= ~stepsImage;
		i1 = Image.new(	~fireBG);
		i2 = Image.new(	~wolfBG);
		i3 = Image.new(	~shrekBG);
		i4 = Image.new(	~walkBG);
		~background=false;
		~knobPos[0,6] = Color.red;
		~knobPos[1,6] = Color.gray;
		~knobPos[2,6] = Color.green;
		~knobPos[3,6] = Color.black;

		//SYNTHDEFS

		// ------STEPS------ //
		SynthDef(\PassettiNeve, {
			// Argument declaration
			arg outBus,
			gate = 1,
			amp = 1,
			envbuf,
			hpfreq = 2000, // parameter that control the snow/dirt ratio
			speed = 1; //speed of steps

			// Variable declaration
			var center,sig2,hpf,verb,shf,lpf, sig, a;

			a = Buffer.readChannel(s,~srcPath,channels:[0]);

			// steps granular synth
			sig2 = GrainBuf.ar(
				numChannels: 1,
				trigger: Impulse.ar(speed+LFNoise1.ar((0.7*speed)).bipolar(speed/4)),
				dur: 0.4,
				sndbuf: a,
				rate: 1,
				pos: 0.34,
				interp: 2,
				pan: 0
			);

			sig = sig2 * BrownNoise.ar(1,0); // multiply the signal by brown noise for crispiness
			verb = FreeVerb.ar(sig,0.2); // reverbering the signal
			shf = PitchShift.ar(verb,0.2,0.2); // pitch shifting the signal
			// filtering signal
			hpf = HPF.ar(shf,hpfreq);
			lpf = LPF.ar(hpf,6000)*6;
			// regulating output amplitude in order to maintain quasi-constant the volume
			// though the frequency content raises
			lpf = lpf*(hpfreq.log10-2000.log10).exp;

			Out.ar(outBus,lpf);
		}).add;


		// ------FROGS & CRICKETS------ //
		SynthDef(\frog, {
			// Arguments declaration
			arg outBus = 0,
			grainPos = 0.162215, // position in % of buff duration of the beginning of the grain
			randomness = 1, // 0.0 - 1.0, parameter that ragulates the irregularity of cries
			excited1 = 1,  // 0.5 - 1.7, parameter that ragulates the crickets' cries speed
			excited2 = 1.7, // 0.5 - 1.7, parameter that ragulates the frogs' cries speed
			ampFront = 1, // amplitude of frogs signal-
			ampRear = 1; // amplitude of crickets signal

			// Variables declaration
			var sig, sig2, mix, out,
			envPitch,env, buff,
			trig, trig2;

			buff = Buffer.readChannel(s, ~srcPath, channels:[0]);
			0.1.wait;
			//trigger for frogs cries
			trig = Trig1.ar((LFSaw.ar(0.3*excited2)+LFSaw.ar(1.2*excited2, 0, 0.25) + (LFNoise1.ar(randomness).range(-0.5, 2)*randomness)), 0.3);

			// Frogs granular synth
			sig = GrainBuf.ar(
				numChannels: 1,
				trigger: Impulse.ar(30 * trig ), // impulses train "opened" by trigger
				dur: 0.01,
				sndbuf: buff,
				rate: 5 + EnvGen.kr(Env.asr(0.3, 1, 0.1), gate: trig), //rate modulation via envelope
				pos: grainPos,
				interp: 2,
				pan: 0,
				envbufnum: -1,
				maxGrains: 512,
				mul: 2.5,
				add: 0
			)*excited2;

			// trigger signal for crickets
			trig2 = Trig1.ar(SinOsc.ar(80), 0.3);
			// Crickets granular synth
			sig2 = GrainBuf.ar(
				numChannels: 1,
				trigger: Impulse.ar(60 * LFPulse.ar((4*excited1) + LFNoise1.ar(1).bipolar(2), 0, 0.3, 0.5, 0.5)),
				dur: 0.01,
				sndbuf: buff,
				rate: 15 + EnvGen.ar(Env.asr(0.2, 2, 0.2), gate:trig2),
				pos: 0.553747,
				interp: 2,
				pan: 0,
				envbufnum: -1,
				maxGrains: 512,
				mul: 0.3,
				add: 0
			)*excited1;

			// mixing signals to one single channel
			mix = Mix([sig, sig2]);
			// low pass filtering output signal
			out = LPF.ar(mix, 1500, 0.3);

			Out.ar(outBus, out);
		}).add;


		// ------WOLF------ //
		SynthDef(\wolf, {
			// Argument declaration
			arg outBus = 0,
			length = 3.5, // parameter that regulate the howls' length
			grainPos = 0.162215,
			occurence = 0.2; // parameter that regulate the time occurrence of howls

			// Variable declaration
			var sig,
			env, env1, envgen1,
			lpf, trig,buff;

			buff = Buffer.readChannel(s, ~srcPath, channels:[0]);

			// trigger signal for envelopes
			trig = Trig1.ar(LFSaw.kr(occurence/2, 1), length + LFNoise1.kr(3).range(-2, 0));

			// envelopes
			env = EnvGen.kr(Env.adsr(1, 0.5, 1, 1.7, 0.8, \sin), trig, 1, 0.1);
			env1 = Env.sine(3.5);
			envgen1= EnvGen.kr(env1, trig);

			// granular synth
			// a great use of noise modulation has been done in order to achieve more natural result
			sig = GrainBuf.ar(
				numChannels: 1,
				trigger: Impulse.ar(envgen1*50*SinOsc.kr(1/7).range(0.8, 1.1) + 350),
				dur: 0.3,
				sndbuf: buff,
				rate: 0.2*env+LFNoise1.kr(4).bipolar(0.001), // rate modulation via envelope and noise
				pos: grainPos,
				interp: 2,
				pan: 0,
				envbufnum: -1,
				maxGrains: 512,
				mul: 1,
				add: 0
			)*(0.8 + LFNoise1.kr(10).bipolar(0.1))*env; // amplitude modulation via Noise and envelope

			// low pass filtering output signal
			lpf = LPF.ar(sig, 900)/2;

			Out.ar(outBus, lpf);

		}).add;

		// ------FIRE------ //
		SynthDef(\fire, {
			// Argument declaration
			arg	outBus = 0,
			grainPos = 0.22, //
			wood = 1; // parameter that aims to simulate the the quantity of burning wood

			// Variables declaration
			var sig1, sig2, sig4,
			mix, out,
			buff, trig;

			buff = Buffer.readChannel(s, ~srcPath, channels:[0]);

			// High sparkles granular synth
			sig1 = GrainBuf.ar(
				numChannels: 1,
				trigger: Dust.ar((0.6*wood)+LFNoise1.ar(3).bipolar(0.2)), // grains are triggered by a random impulses train frequency modulated by wood parameter and noise
				dur: 0.001,
				sndbuf: buff,
				rate: 3*SinOsc.ar(0.2).range(1,2), // rate modulation
				pos: grainPos,
				interp: 2,
				pan: 0,
				envbufnum: -1,
				maxGrains: 512,
				mul: 10*LFNoise1.ar(0.3).range(1,1.5) + (wood/100), // amplitude modulation via noise and wood parameter
				add: 0
			);

			// Low sparkles granular synth
			sig2 = GrainBuf.ar(
				numChannels: 1,
				trigger: Dust.ar(LFNoise1.ar(wood).range(1, 2)), // grains are triggered by a random impulses train frequency modulated by wood parameter and noise
				dur: 0.002,
				sndbuf: buff,
				rate: 3*LFNoise1.ar(0.2).range(1,2), // rate modulation
				pos: 0.241694,
				interp: 2,
				pan: 0,
				envbufnum: -1,
				maxGrains: 512,
				mul: LFNoise1.ar(0.3).range(1,2) + (wood/100), // amp modulation
				add: 0
			);

			// Noise granular synth
			sig4 = GrainBuf.ar(
				numChannels: 1,
				trigger: Dust.ar(20000+LFNoise1.ar(10).bipolar(1000)),
				dur: 0.0005,
				sndbuf: buff,
				rate: 4,
				pos: grainPos,
				interp: 2,
				pan: 0,
				envbufnum: -1,
				maxGrains: 512,
				mul: (0.3 + SinOsc.ar(0.2+LFNoise1.ar(1).bipolar(0.1)).range(-0.05, 0))*0.1 + (wood/100), //amp modulation
				add: 0
			)*LFNoise1.ar(wood).range(0.5, 1.5); // amp modulation

			sig2 = FreeVerb.ar(sig2, 0.8, 0.3, 0); // reverb on low sparkles

			// mix all signals together
			mix = Mix([sig1, sig2, sig4]);

			// filtering aout signal
			out = LPF.ar(mix, 2000);
			out = HPF.ar(out, 500);
			//reverbering out signal
			out = FreeVerb.ar(out, 0.1);
			// compression ratio 5:1 @ -6dB threshold, AT: 1ms, RT: 200ms
			out = Compander.ar(out, out, (-6).dbamp, 1, 1/5, 0.001, 0.2);
			Out.ar(outBus, out);
		}).add;

		// Stereo field positioner synth
		SynthDef(\positioner,{
			// Arguments declaration
			arg inBus=0, mainOut=0, effectOut, angle = 0, radius = 0 ;

			// Variables declaration
			var val,valEf, input,effect, output, panMain,panEf, dbStart=20, inGain, efGain, dBatt;

			// dB SPL attenuation due to distance from source
			dBatt = 20 * (1/(radius.linlin(0,1,1,30))).log10;
			dBatt.postln;

			inGain = dbStart+dBatt; // dry send gain in dB
			efGain = (0.1+(0.1*inGain)); // effect send gain in dB

			inGain = inGain.dbamp; // dry send gain in amplitude
			efGain = efGain.dbamp; // effect send gain in amplitude

			input = In.ar(inBus,1); // read signal from inBus

			val = input*inGain; // dry send signal
			valEf = input*efGain; // effect send signal

			panMain = Pan2.ar(val,angle); // dry send signal panned
			panEf = Pan2.ar(valEf,angle); // effect send signal panned

			Out.ar(mainOut,panMain); // dry signal writing on dry bus
			Out.ar(effectOut,panEf); // effect signal writing on effect bus
		}).add;

		// Environmental reverb synth
		SynthDef(\roomer,{
			// Argument declaration
			arg inBus, outBus = 0, dimension=0.2, mix=1.0, amp=0, room=0.8, damp=0.3, radius;

			// Variable declaration
			var input, out,outputL,outputR,rev,yL,yR,zL,zR;

			// input reading from inBus
			input = In.ar(inBus,2);

			// Reverb
			out = FreeVerb2.ar(
				input[0],
				input[1],
				mix: 1,
				room: room,
				damp: damp,
				mul: 1.0,
				add: 0.0

			);

			// bandpass filtering out signal
			out = BPF.ar(out, 3000)*(amp).dbamp;
			Out.ar(outBus,out);
		} ).add;

		// Scope synth, it takes a signal and send it out to a buffer at audio rate to visualize the signal
		SynthDef(\scoping,{
			arg bus, buffy,outBus=0,amp=1;
			var in;
			in = In.ar(bus,1)*amp;
			ScopeOut2.ar(in, buffy);
		}).add;

		SynthDef(\s1, {arg bus;
			Out.ar(bus, SinOsc.ar(100,0.0,0.5))
		}).add;

		// Master monitor, takes audio from inBus and send out a control rate to visualize master level
		SynthDef(\stereoMonitor,{
			// Arguments declaration
			arg inBus=0,krBus;

			// Variable declaration
			var input,ampL,ampR;

			input =In.ar(inBus,2);

			ampL = Amplitude.kr(input[0]);
			ampR = Amplitude.kr(input[1]);// track the signal's amplitude
			Out.kr(krBus, [ampL,ampR]);  // write amplitude data to control bus
		}).add;

		// Master channel
		SynthDef(\stereoMaster,{
			// Arguments declaration
			arg inBus, outBus, amp = 10, ratio=4;

			// Variable declaration
			var in = In.ar(inBus,2);

			// amplification of input
			in = in*amp.dbamp;
			// Compression ratio 4:1 @ -10dB threshold, AT: 10ms, RT: 50ms
			in = Compander.ar(in, in, (-10).dbamp, 1, 1/ratio, 0.01, 0.05);
			// Limiter, to avoid clipping
			in = Limiter.ar(in, 0.8, 0.01);

			Out.ar(outBus,in);
		}).add;

		0.2.wait;

		Window.closeAll;
		// main
		w = Window.new("PLASgui",Rect(winRL,winUpDown,winWidth,winHeight), false)
		.front
		.alwaysOnTop_(false)
		.onClose_({
			Window.closeAll;
			s.freeAll;
			~bufWolf.free;
			~bufFire.free;
			~bufStep.free;
			~bufFrog.free;
			~fireBus.free;
			~wolfBus.free;
			~frogBus.free;
			~stepBus.free;
			~updateIndicator.stop;
			"SYSTEM STOPPED...".postln;
		}).drawFunc = {


			Pen.addRect(w.view.bounds);
			Pen.fillAxialGradient(w.view.bounds.leftTop, w.view.bounds.rightBottom, Color.fromHexString("#05668d"), Color.fromHexString("#028090"));


			Pen.perform([\stroke, \fill].choose);

			Pen.addRect(Rect(marg,marg,sectWinWidth,sectWinHeight))
			.width_(5)
			//.fillColor_(Color.black)
			//.fill
			.strokeColor_(Color.fromHexString("#78cdd7"))
			.stroke;

			Pen.addRect(Rect(marg,(2*marg)+sectWinHeight,sectWinWidth,sectWinHeight))
			.width_(5)
			.strokeColor_(Color.fromHexString("#78cdd7"))
			.stroke;

			Pen.addRect(Rect(marg,(3*marg)+(2*sectWinHeight),sectWinWidth,sectWinHeight))
			.width_(5)
			.strokeColor_(Color.fromHexString("#78cdd7"))
			.stroke;

			Pen.addRect(Rect(marg,(4*marg)+(3*sectWinHeight),sectWinWidth,sectWinHeight))
			.width_(5)
			.strokeColor_(Color.fromHexString("#78cdd7"))
			.stroke;

			Pen.addRect(Rect(750,marg,sectWinHeight,winHeight-(3*marg)-sectWinHeight))
			.width_(5)
			.strokeColor_(Color.fromHexString("#78cdd7"))
			.stroke;

			Pen.addRect(Rect(750,(4*marg)+(3*sectWinHeight),sectWinHeight,sectWinHeight))
			.width_(5)
			.strokeColor_(Color.fromHexString("#78cdd7"))
			.stroke;

			if(~background == true,{
				i1.tileInRect(Rect(marg,marg,sectWinWidth,sectWinHeight),nil,2,1.0);
				i2.tileInRect(Rect(marg,(2*marg)+sectWinHeight,sectWinWidth,sectWinHeight),nil,2,0.7);
				i3.tileInRect(Rect(marg,(3*marg)+(2*sectWinHeight),sectWinWidth,sectWinHeight),nil,2,1.0);
				i4.tileInRect(Rect(marg,(4*marg)+(3*sectWinHeight),sectWinWidth,sectWinHeight),nil,2,1.0);
			},
			{});


			Pen.addRect(Rect(300,60, 150, 60))
			.width_(8)
			.strokeColor_(Color.fromHexString("#78cdd7"))
			.stroke;

			Pen.addRect(Rect(300,216, 150, 60))
			.width_(8)
			.strokeColor_(Color.fromHexString("#78cdd7"))
			.stroke;

			Pen.addRect(Rect(300,373, 150, 60))
			.width_(8)
			.strokeColor_(Color.fromHexString("#78cdd7"))
			.stroke;

			Pen.addRect(Rect(300,529, 150, 60))
			.width_(8)
			.strokeColor_(Color.fromHexString("#78cdd7"))
			.stroke;

		};


		Button.new(w, Rect(5,5,15,15))
		.states_([
			["", Color.black, Color.fromHexString("#78cdd7")],
			["",Color.white, Color.white(1.0)]
		]).action_({ |b| QtGUI.palette = if(b.value == 0);
			if(b.value==0,{
				~background = false;
				w.refresh;
			},{
				~background = true;
				w.refresh;
		});});


		/*


		Button.new(w, Rect(winWidth-20,5,15,15))
		.states_([
		["", Color.black, Color.fromHexString("#78cdd7")],
		["",Color.white, Color.white(1.0)]
		])
		.action_({|panner|
		if(panner.value==1,{

		wp.visible = true;

		},{wp.visible=false})
		});

		Button.new(w, Rect(winWidth-20,winHeight-20,15,15))
		.states_([
		["", Color.black, Color.fromHexString("#78cdd7")],
		["",Color.white, Color.white(1.0)]
		]);

		Button.new(w, Rect(5,winHeight-20,15,15))
		.states_([
		["", Color.black, Color.fromHexString("#78cdd7")],
		["",Color.white, Color.white(1.0)]
		]);
		*/



		// sections----------------------------------------------------

		w1 = CompositeView(w,Rect(marg,marg,sectWinWidth,sectWinHeight));
		//.background_(Color.new255(30,144,255));

		w2 = CompositeView(w,Rect(marg,(2*marg)+sectWinHeight,sectWinWidth,sectWinHeight));
		//.background_(Color.new255(30,144,255));

		w3 = CompositeView(w,Rect(marg,(3*marg)+(2*sectWinHeight),sectWinWidth,sectWinHeight));
		//.background_(Color.new255(30,144,255));

		w4 = CompositeView(w,Rect(marg,(4*marg)+(3*sectWinHeight),sectWinWidth,sectWinHeight));
		//.background_(Color.new255(30,144,255));

		w5 = CompositeView(w,Rect(750,marg,sectWinHeight,winHeight-(2*marg)));
		//.background_(Color.white);

		w6 = CompositeView(w,Rect(750,(4*marg)+(3*sectWinHeight),sectWinHeight,sectWinHeight));
		v6 = UserView(w,Rect(750,(4*marg)+(3*sectWinHeight),sectWinHeight,sectWinHeight));
		v6.drawFunc_({
			var myX,myY;
			var radius = (sectWinHeight/2)-3;
			Pen.addRect(Rect(0,0,sectWinHeight,sectWinHeight))
			.fillRadialGradient(((sectWinHeight/2))@((sectWinHeight)),(sectWinHeight/2)@(sectWinHeight),30,200,
				Color.fromHexString("#05668d"), Color.fromHexString("#78cdd7"))
			.stroke
			.addArc(((sectWinHeight/2))@((sectWinHeight)),5,pi,2pi)
			.color_(Color.white)
			.fill;

			Pen.addArc(((sectWinHeight/2))@((sectWinHeight)),radius,pi,2pi)
			.strokeColor_(Color.white)
			.alpha_(0.5)
			.stroke;

			Pen.addArc(((sectWinHeight/2))@((sectWinHeight)),radius/4*3,pi,2pi)
			.strokeColor_(Color.white)
			.alpha_(0.4)
			.stroke;


			Pen.addArc(((sectWinHeight/2))@((sectWinHeight)),radius/2,pi,2pi)
			.strokeColor_(Color.white)
			.alpha_(0.3)
			.stroke;

			Pen.addArc(((sectWinHeight/2))@((sectWinHeight)),radius/4,pi,2pi)
			.strokeColor_(Color.white)
			.alpha_(0.2)
			.stroke
			.alpha_(1);
			//~knobPos[0,0].postln;
			for(0,numOfPoints-1,{
				arg i;
				//~knobPos[i,0].postln;
				//"qui".postln;

				myX=(((~knobPos[i,0])/(width-10))*(sectWinHeight-3));
				//"quo".postln;
				myY=(((~knobPos[i,1]/(height-10))*((sectWinHeight/2)-3))+(sectWinHeight/2));
				//"qua".postln;
				Pen.color_(~knobPos[i,6]);
				Pen.addArc((myX)@(myY),5,0,2pi);
				Pen.fillStroke;
			})

		});

		v6.mouseDownAction = {
			arg view, x,y, m;
			//var vis;
			// if(~wpBool==false,{
			/*if(~wp.isClosed==true,{
			~wpFunc.play;
			// ~wp.visible_(true);
			},{
			if(~wp.visible == true, {
			~wp.visible=false
			},{
			~wp.visible=true

			});

			});*/
			if(~wpBool==false,
				{
					~wpFunc.value;
					~wp.visible_(true);
					~wpBool = true;
				},
				{
					~wp.close;
					~wpBool = false;
				}
			)

		};






		// LABEL%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		~labeltitle = StaticText(w, Rect((sectWinWidth/2)-(150/2),15,200,titleHeight+4))
		.string_("GRANULANDS")
		.align_(\center)
		.font_(Font("Helvetica"/*"Cooper Black""Eras Bold ITC""Harlow Solid Italic""Matura MT Script Capitals""Swis721 BlkEx BT"*/, 20).boldVariant)
		.stringColor_(Color.black)
		.background_(Color.white);

		//FIRE%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		~fireBus = Bus.audio(s,1);
		~fireSynth = Synth.newPaused(\fire,[\outBus,~fireBus]);

		~labelFire = StaticText(w1, Rect(20,0,titleWidth,titleHeight))
		.string_("FIRE")
		.align_(\center)
		.font_(Font("Helvetica", 18).boldVariant)
		.background_(Color.white);

		~knobLabelWood= StaticText(w1, Rect(3*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Wood")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		~knobWood = Knob(w1, Rect(3*knobIntraDist,50,knobDim,knobDim))
		.value_(1/3)
		.background_(Color.fromHexString("#78cdd7"))
		.color_(~colors)
		.mode_(\vert)
		.action_({
			arg wood;
			~numberboxWood.value_(wood.value.linlin(0,1,0.5,2));
			~fireSynth.set(\wood,~knobWood.value.linlin(0,1,0.5,2))
		});

		~numberboxWood = NumberBox(w1, Rect(3*knobIntraDist,(knobIntraDist)+knobDim+(1.7*marg),numBoxWidth,numBoxHeight))
		.value_(1)
		.background_(Color.white)
		.align_(\center)
		.action_({
			arg wood;
			~knobWood.valueAction_(wood.value.linlin(0.5,2,0,1));
		});

		~knobLabelPanFire= StaticText(w1, Rect(36*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Pan")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		/*~knobPanFire*/ ~knobPos[0,2] = Knob(w1, Rect(36*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.centered_(true)
		.value_(0.5)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_(
			{
				var angle,distance,x,y;
				angle = ~knobPos[0,2].value.linlin(0,1,-pi/2,pi/2);
				distance = ~knobPos[0,3].value.linlin(0,1,0,height-10);
				x = (((distance*((angle).sin))+centerPosX)+elRadius);
				y = ((((height-10)-(distance*(angle).cos)))+elRadius);
				~knobPos[0,0] = x;
				~knobPos[0,1] = y;
				~knobPos[0,5].set(\angle,~knobPos[0,2].value.linlin(0,1,-1,1));
				~knobPos[0,5].set(\radius,~knobPos[0,3].value);
				v.refresh;
				v6.refresh;
		});

		~knobLabelDistFire= StaticText(w1, Rect(42*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Distance")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		/*~knobDistFire*/ ~knobPos[0,3] = Knob(w1, Rect(42*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.value_(0.2)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_(
			{
				var angle,distance,x,y;
				angle = ~knobPos[0,2].value.linlin(0,1,-pi/2,pi/2);
				distance = ~knobPos[0,3].value.linlin(0,1,20,height-10);
				x = (((distance*((angle).sin))+centerPosX)+elRadius);
				y = ((((height-10)-(distance*(angle).cos)))+elRadius);
				~knobPos[0,0] = x;
				~knobPos[0,1] = y;
				~knobPos[0,5].set(\angle,~knobPos[0,2].value.linlin(0,1,-1,1));
				~knobPos[0,5].set(\radius,~knobPos[0,3].value);
				v.refresh;
				v6.refresh;
		});
		//"passed1?".postln;
		~b1 = Button.new(w1, Rect(48*knobIntraDist,40,60,knobDim))
		.states_([
			["PLAY", Color.black, Color.fromHexString("#78cdd7")],
			["STOP",Color.white, Color.red(0.5)]
		])
		.action_({ arg b,sum;
			QtGUI.palette = if(b.value == 0);
			//"aqi".postln;
			if(b.value == 0,
				{
					~fireSynth.run(false);
					//postln("firesynth true");

				},
				{
					~fireSynth.run(true);
					//postln("firesynth false");

				}
			);
			sum = ~b1.value+~b2.value+~b3.value+~b4.value;
			if(sum>0, {
				~b5.value_(1)
			},{
				~b5.value_(0)
			});
		});

		//WOLF%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


		~wolfBus = Bus.audio(s,1);
		~wolfSynth = Synth.newPaused(\wolf,[\outBus,~wolfBus]);


		~labelWolf = StaticText(w2, Rect(20,0,titleWidth,titleHeight))
		.string_("WOLF")
		.align_(\center)
		.font_(Font("Helvetica", 18).boldVariant)
		.background_(Color.white);

		~knobLabelLenght= StaticText(w2, Rect(3*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Lenght")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		~knobLenght = Knob(w2, Rect(3*knobIntraDist,50,knobDim,knobDim))
		.background_(Color.fromHexString("#78cdd7"))
		.color_(~colors)
		.value_(0.4)
		.mode_(\vert)
		.action_({
			arg lenght;
			~numberboxLenght.value_(lenght.value.linlin(0,1,2.5,5));
			~wolfSynth.set(\length,~knobGrain.value.linlin(0,1,2.5,5))
		});

		~numberboxLenght = NumberBox(w2, Rect(3*knobIntraDist,(knobIntraDist)+knobDim+(1.7*marg),numBoxWidth,numBoxHeight))
		.value_(3.5)
		.background_(Color.white)
		.align_(\center)
		.action_({
			arg lenght;
			~knobLenght.valueAction_(lenght.value.linlin(2.5,5,0,1));
		});

		~knobLabelGrain= StaticText(w2, Rect(8*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Grain")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		~knobGrain = Knob(w2, Rect(8*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.value_(0.162215)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_({
			arg grain;
			~numberboxGrain.value_(grain.value.linlin(0,1,0,1));
			~wolfSynth.set(\grainPos,~knobGrain.value.linlin(0,1,0,1));
		});

		~numberboxGrain = NumberBox(w2, Rect(8*knobIntraDist,(knobIntraDist)+knobDim+(1.7*marg),numBoxWidth,numBoxHeight))
		.background_(Color.white)
		.value_(0.162215)
		.align_(\center)
		.action_({
			arg grain;
			~knobGrain.valueAction_(grain.value.linlin(0,1,0,1));
		});

		~knobLabelOcc = StaticText(w2, Rect(12*knobIntraDist,1.1*marg,1.5*knobLabelWidth,20))
		.string_("Occurrence")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		~knobOcc = Knob(w2, Rect(13*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.value_(0.25)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_({
			arg occ;
			~numberboxOcc.value_(occ.value.linlin(0,1,0.1,0.5));
			~wolfSynth.set(\occurence,~knobOcc.value.linlin(0,1,0.1,0.5));
		});

		~numberboxOcc = NumberBox(w2, Rect(13*knobIntraDist,(knobIntraDist)+knobDim+(1.7*marg),numBoxWidth,numBoxHeight))
		.value_(0.2)
		.background_(Color.white)
		.align_(\center)
		.action_({
			arg occ;
			~knobOcc.valueAction_(occ.value.linlin(0.1,0.5,0,1));
		});

		~knobLabelPanWolf= StaticText(w2, Rect(36*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Pan")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		/*~knobPanWolf*/~knobPos[1,2] = Knob(w2, Rect(36*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.centered_(true)
		.value_(0.5)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_(
			{
				var angle,distance,x,y;
				angle = ~knobPos[1,2].value.linlin(0,1,-pi/2,pi/2);
				distance = ~knobPos[1,3].value.linlin(0,1,0,height-10);
				x = (((distance*((angle).sin))+centerPosX)+elRadius);
				y = ((((height-10)-(distance*(angle).cos)))+elRadius);
				~knobPos[1,0] = x;
				~knobPos[1,1] = y;
				~knobPos[1,5].set(\angle,~knobPos[1,2].value.linlin(0,1,-1,1));
				~knobPos[1,5].set(\radius,~knobPos[1,3].value);
				v.refresh;
				v6.refresh;
		});

		~knobLabelDistWolf= StaticText(w2, Rect(42*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Distance")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		/*~knobDistWolf*/ ~knobPos[1,3]= Knob(w2, Rect(42*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.value_(0.4)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_(
			{
				var angle,distance,x,y;
				angle = ~knobPos[1,2].value.linlin(0,1,-pi/2,pi/2);
				distance = ~knobPos[1,3].value.linlin(0,1,0,height-10);
				x = (((distance*((angle).sin))+centerPosX)+elRadius);
				y = ((((height-10)-(distance*(angle).cos)))+elRadius);
				~knobPos[1,0] = x;
				~knobPos[1,1] = y;
				~knobPos[1,5].set(\angle,~knobPos[1,2].value.linlin(0,1,-1,1));
				~knobPos[1,5].set(\radius,~knobPos[1,3].value);
				v.refresh;
				v6.refresh;
		});

		~b2 = Button.new(w2, Rect(48*knobIntraDist,40,60,knobDim))
		.states_([
			["PLAY", Color.black, Color.fromHexString("#78cdd7")],
			["STOP",Color.white, Color.red(0.5)]
		]).action_({ |b,sum| QtGUI.palette = if(b.value == 0);
			if(b.value == 0,
				{
					~wolfSynth.run(false);
					//postln("wolfsynth true");

				},
				{
					~wolfSynth.run(true);
					//postln("wolfsynth false");

				}
			);
			sum = ~b1.value+~b2.value+~b3.value+~b4.value;
			if(sum>0, {
				~b5.value_(1)
			},{
				~b5.value_(0)
			});
		});



		//FROG%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		/*
		arg buff = a,
		outBus = 0,
		grainPos = 0.162215,
		randomness = 1, // 0.0 - 1.0
		excited1 = 1,  // 0.5 - 1.7
		excited2 = 1.7;  // 0.5 - 1.7
		*/
		~frogBus = Bus.audio(s,1);
		~frogSynth = Synth.newPaused(\frog,[\outBus,~frogBus]);
		~labelFrog = StaticText(w3, Rect(20,0,1.5*titleWidth,titleHeight))
		.string_("CRICKETS-FROGS")
		.align_(\center)
		.font_(Font("Helvetica", 18).boldVariant)
		.background_(Color.white);

		~randomKnobLabel= StaticText(w3, Rect(3*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Random")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		~randomKnob = Knob(w3, Rect(3*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.value_(1)
		.action_({
			arg boh1;
			~randomNumberbox.value_(boh1.value.linlin(0,1,0,1));
			~frogSynth.set(\randomness,~randomKnob.value);
		});

		~randomNumberbox = NumberBox(w3, Rect(3*knobIntraDist,(knobIntraDist)+knobDim+(1.7*marg),numBoxWidth,numBoxHeight))
		.background_(Color.white)
		.align_(\center)
		.value_(1)
		.action_({
			arg boh1;
			~randomKnob.valueAction_(boh1.value.linlin(0,1,0,1));
			~frogSynth.set(\randomness,~randomKnob.value.linlin(0,1,0,1))
		});

		~excited1KnobLabel= StaticText(w3, Rect(8*knobIntraDist,1.1*marg,knobLabelWidth+5,20))
		.string_("Occur. 1")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		~excited1Knob = Knob(w3, Rect(8*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.mode_(\vert)
		.value_(5/12)
		.background_(Color.fromHexString("#78cdd7"))
		.action_({
			arg boh2;
			~excited1Numberbox.value_(boh2.value.linlin(0,1,0.5,1.7));
			~frogSynth.set(\excited1,~excited1Knob.value.linlin(0,1,0.5,1.7));
		});

		~excited1Numberbox = NumberBox(w3, Rect(8*knobIntraDist,(knobIntraDist)+knobDim+(1.7*marg),numBoxWidth,numBoxHeight))
		.background_(Color.white)
		.value_(1)
		.align_(\center)
		.action_({
			arg boh2;
			~excited1Knob.valueAction_(boh2.value.linlin(0.5,1.7,0,1));
			//~frogSynth.set(\excited1,~excited1Knob.value.linlin(0.5,1.7,0,1));
		});

		~excited2KnobLabel = StaticText(w3, Rect(12*knobIntraDist,1.1*marg,1.5*knobLabelWidth,20))
		.string_("Occur. 2")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		~excited2Knob = Knob(w3, Rect(13*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.mode_(\vert)
		.value_(5/12)
		.background_(Color.fromHexString("#78cdd7"))
		.action_({
			arg boh3;
			~excited2Numberbox.value_(boh3.value.linlin(0,1,0.5,1.7));
			~frogSynth.set(\excited2,~excited2Knob.value.linlin(0,1,0.5,1.7));
		});

		~excited2Numberbox = NumberBox(w3, Rect(13*knobIntraDist,(knobIntraDist)+knobDim+(1.7*marg),numBoxWidth,numBoxHeight))
		.value_(1)
		.background_(Color.white)
		.align_(\center)
		.action_({
			arg boh3;
			~excited2Knob.valueAction_(boh3.value.linlin(0.5,1.7,0,1));
		});

		~knobLabelPanFrog= StaticText(w3, Rect(36*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Pan")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		/*~knobPanFrog*/~knobPos[2,2] = Knob(w3, Rect(36*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.centered_(true)
		.value_(0.5)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_(
			{
				var angle,distance,x,y;
				angle = ~knobPos[2,2].value.linlin(0,1,-pi/2,pi/2);
				distance = ~knobPos[2,3].value.linlin(0,1,0,height-10);
				x = (((distance*((angle).sin))+centerPosX)+elRadius);
				y = ((((height-10)-(distance*(angle).cos)))+elRadius);
				~knobPos[2,0] = x;
				~knobPos[2,1] = y;
				~knobPos[2,5].set(\angle,~knobPos[2,2].value.linlin(0,1,-1,1));
				~knobPos[2,5].set(\radius,~knobPos[2,3].value);
				v.refresh;
				v6.refresh;
		});

		~knobLabelDistFrog= StaticText(w3, Rect(42*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Distance")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		/*~knobDistFrog*/ ~knobPos[2,3] = Knob(w3, Rect(42*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.value_(0.6)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_(
			{
				var angle,distance,x,y;
				angle = ~knobPos[2,2].value.linlin(0,1,-pi/2,pi/2);
				distance = ~knobPos[2,3].value.linlin(0,1,0,height-10);
				x = (((distance*((angle).sin))+centerPosX)+elRadius);
				y = ((((height-10)-(distance*(angle).cos)))+elRadius);
				~knobPos[2,0] = x;
				~knobPos[2,1] = y;
				~knobPos[2,5].set(\angle,~knobPos[2,2].value.linlin(0,1,-1,1));
				~knobPos[2,5].set(\radius,~knobPos[2,3].value);
				v.refresh;
				v6.refresh;
		});

		~b3 = Button.new(w3, Rect(48*knobIntraDist,40,60,knobDim))
		.states_([
			["PLAY", Color.black, Color.fromHexString("#78cdd7")],
			["STOP",Color.white, Color.red(0.5)]
		]).action_({ |b,sum|
			QtGUI.palette = if(b.value == 0);
			if(b.value == 0,
				{
					~frogSynth.run(false);
					//postln("frogsynth true");
				},
				{
					~frogSynth.run(true);
					//postln("frogsynth false");
				}
			);
			sum = ~b1.value+~b2.value+~b3.value+~b4.value;
			if(sum>0, {
				~b5.value_(1)
			},{
				~b5.value_(0)
			});
		});



		//STEP%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


		~stepBus = Bus.audio(s,1);
		~stepSynth = Synth.newPaused(\PassettiNeve,[\outBus,~stepBus]);
		~labelStep = StaticText(w4, Rect(20,0,1.5*titleWidth,titleHeight))
		.string_("FOOTSTEPS")
		.align_(\center)
		.font_(Font("HelveticaC", 18).boldVariant)
		.background_(Color.white);

		~knobLabelSpeed= StaticText(w4, Rect(3*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Speed")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		~knobSpeed = Knob(w4, Rect(3*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_({
			arg speed;
			~numberboxSpeed.value_(speed.value.linlin(0,1,1,2));
			~stepSynth.set(\speed,~knobSpeed.value.linlin(0,1,1,2));

		});

		~numberboxSpeed = NumberBox(w4, Rect(3*knobIntraDist,(knobIntraDist)+knobDim+(1.7*marg),numBoxWidth,numBoxHeight))
		.value_(1)
		.background_(Color.white)
		.align_(\center)
		.action_({
			arg speed;
			~knobSpeed.valueAction_(speed.value.linlin(1,2,0,1));
			~stepSynth.set(\speed,~knobSpeed.value.linlin(1,2,0,1));
		});

		~knobLabelSnowy= StaticText(w4, Rect(7*knobIntraDist,1.1*marg,1.5*knobLabelWidth,20))
		.string_("Dirt/Snow")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		~knobSnowy = Knob(w4, Rect(8*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.mode_(\vert)
		.value_(1)
		.background_(Color.fromHexString("#78cdd7"))
		.action_({
			arg snowy;
			~numberboxSnowy.value_(snowy.value.linlin(0,1,200,2000));
			~stepSynth.set(\hpfreq,~knobSnowy.value.linlin(0,1,200,2000));
		});

		~numberboxSnowy = NumberBox(w4, Rect(8*knobIntraDist,(knobIntraDist)+knobDim+(1.7*marg),numBoxWidth,numBoxHeight))
		.value_(2000)
		.background_(Color.white)
		.align_(\center)
		.action_({
			arg snowy;
			~knobSnowy.valueAction_(snowy.value.linlin(200,2000,0,1));
			~stepSynth.set(\hpfreq,~knobSnowy.value.linlin(200,2000,0,1));

		});


		~knobLabelPanStep= StaticText(w4, Rect(36*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Pan")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		/*~knobPanStep*/ ~knobPos[3,2] = Knob(w4, Rect(36*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.centered_(true)
		.value_(0.5)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_(
			{
				var angle,distance,x,y;
				angle = ~knobPos[3,2].value.linlin(0,1,-pi/2,pi/2);
				distance = ~knobPos[3,3].value.linlin(0,1,0,height-10);
				x = (((distance*((angle).sin))+centerPosX)+elRadius);
				y = ((((height-10)-(distance*(angle).cos)))+elRadius);
				~knobPos[3,0] = x;
				~knobPos[3,1] = y;
				~knobPos[3,5].set(\angle,~knobPos[3,2].value.linlin(0,1,-1,1));
				~knobPos[3,5].set(\radius,~knobPos[3,3].value);
				v.refresh;
				v6.refresh;
		});

		~knobLabelDistStep= StaticText(w4, Rect(42*knobIntraDist,1.1*marg,knobLabelWidth,20))
		.string_("Distance")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.background_(Color.rand);

		/*~knobDistStep*/~knobPos[3,3] = Knob(w4, Rect(42*knobIntraDist,50,knobDim,knobDim))
		.color_(~colors)
		.value_(0.9)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_(
			{
				var angle,distance,x,y;
				angle = ~knobPos[3,2].value.linlin(0,1,-pi/2,pi/2);
				distance = ~knobPos[3,3].value.linlin(0,1,0,height-10);
				x = (((distance*((angle).sin))+centerPosX)+elRadius);
				y = ((((height-10)-(distance*(angle).cos)))+elRadius);
				~knobPos[3,0] = x;
				~knobPos[3,1] = y;
				~knobPos[3,5].set(\angle,~knobPos[3,2].value.linlin(0,1,-1,1));
				~knobPos[3,5].set(\radius,~knobPos[3,3].value);
				v.refresh;
				v6.refresh;
		});

		~b4=Button.new(w4, Rect(48*knobIntraDist,40,60,knobDim))
		.states_([
			["PLAY", Color.black, Color.fromHexString("#78cdd7")],
			["STOP",Color.white, Color.red(0.5)]
		])
		.action_(
			{ |b,sum| QtGUI.palette = if(b.value == 0);
				if(b.value == 0,
					{

						~stepSynth.run(false);
						~b5.value_(0);
					},
					{
						~stepSynth.run(true);
				});
				sum = ~b1.value+~b2.value+~b3.value+~b4.value;
				if(sum>0, {
					~b5.value_(1)
				},{
					~b5.value_(0)
				});
		});

		//SIDE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		~labelSide = StaticText(w5, Rect(15,0,sectWinHeight-30,titleHeight))
		.string_("MASTER")
		.align_(\center)
		.font_(Font("Helvetica", 18).boldVariant)
		.background_(Color.white);

		~b5 = Button.new(w5, Rect(knobIntraDist,40,105,knobDim))
		.states_([
			["PLAY ALL", Color.black, Color.fromHexString("#78cdd7")],
			["STOP ALL",Color.white, Color.red(0.5)]
		])
		.action_(
			{
				|b| QtGUI.palette = if(b.value == 0);
				if(b.value == 0,
					{
						~b1.valueAction_(0);
						~b2.valueAction_(0);
						~b3.valueAction_(0);
						~b4.valueAction_(0);
					},
					{
						~b1.valueAction_(1);
						~b2.valueAction_(1);
						~b3.valueAction_(1);
						~b4.valueAction_(1);

				});
		});


		~knobLabelReverb = StaticText(w5, Rect(1.2*knobIntraDist,110,2*knobDim,30))
		.string_("Reverb")
		.align_(\center)
		.font_(Font("arial", 18).boldVariant)
		.stringColor_(Color.white);
		//.backColor_(Color.white);

		~knobRoom = Knob(w5, Rect(0.7*knobIntraDist,160+15,knobDim,knobDim))
		.color_(~colors)
		.value_(0.7)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_({
			arg room;
			~roomer.set(\room,~knobRoom.value.linlin(0,1,0,1));

		});

		~knobLabelRoom = StaticText(w5, Rect(0.7*knobIntraDist,130+10,knobDim,knobDim))
		.string_("Room")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);


		~knobDamp = Knob(w5, Rect(5.5*knobIntraDist,160+15,knobDim,knobDim))
		.color_(~colors)
		.value_(0.3)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_({
			arg damp;
			~roomer.set(\damp,~knobDamp.value.linlin(0,1,0,1));

		});
		~knobLabelDamp = StaticText(w5, Rect(5.5*knobIntraDist,130+10,knobDim,knobDim))
		.string_("Damp")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);

		~knobLvl = Knob(w5, Rect(knobIntraDist*3.1,240,knobDim,knobDim))
		.color_(~colors)
		.value_(0.5)
		.mode_(\vert)
		.background_(Color.fromHexString("#78cdd7"))
		.action_({
			arg lvl;
			~roomer.set(\amp,~knobLvl.value.linlin(0,1,-18,18));
		});

		~knobLabelLvl = StaticText(w5, Rect(3.1*knobIntraDist,205,knobDim,knobDim))
		.string_("Lvl")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);


		~knobLabelMasterVolume = StaticText(w5, Rect(1.2*knobIntraDist,300,2*knobDim,30))
		.string_("Master Volume")
		.align_(\center)
		.font_(Font("arial", 12).boldVariant)
		.stringColor_(Color.white);
		//.backColor_(Color.white);

		~masterVolume = Volume.new(s, 0, 2, -90, 6);

		~spec = ControlSpec((3.16*(10**(-5))).ampdb, 2.ampdb, \db, units:"dB");


		~masterSlider = Slider.new(w5, Rect(10,327,30,sectWinHeight-28))
		.orientation_(\vertical)
		.background_(Color.fromHexString("#78cdd7"))
		.thumbSize_(20)
		.knobColor_(Color.fromHexString("#78cdd7"))
		.value_(~spec.unmap(0))
		.action = {
			~masterVolume.volume = ~spec.map(~masterSlider.value);
		};




		//master and reverb bus and Synths
		~effectBus =Bus.audio(s,2);

		{~roomer= Synth.tail(nil,\roomer,[\inBus,~effectBus,\outBus,0])}.defer(0.3);
		{~stereoMaster = Synth.after(~roomer,\stereoMaster,[\inBus,0,\outBus,0,\amp,1])}.defer(0.4);

		//oscilloscope creation
		{Synth.after(~fireSynth,\scoping, [\buffy, ~bufFire.bufnum, \bus, ~fireBus,\amp,8])}.defer(0.18);
		{Synth.after(~wolfSynth,\scoping, [\buffy, ~bufWolf.bufnum, \bus, ~wolfBus,\amp,8])}.defer(0.18);
		{Synth.after(~frogSynth,\scoping, [\buffy, ~bufFrog.bufnum, \bus, ~frogBus,\amp,8])}.defer(0.18);
		{Synth.after(~stepSynth,\scoping, [\buffy, ~bufStep.bufnum, \bus, ~stepBus,\amp,8])}.defer(0.18);

		//positioner creation
		{~knobPos[0,5] = Synth.after(~fireSynth,\positioner, [\inBus, ~fireBus,\mainOut,0,\angle,~knobPos[0,2].value.linlin(0,1,-1,1),\radius,~knobPos[0,3].value,\effectOut,~effectBus])}.defer(0.2);
		{~knobPos[1,5] = Synth.after(~wolfSynth,\positioner, [\inBus, ~wolfBus,\mainOut,0,\angle,~knobPos[1,2].value.linlin(0,1,-1,1),\radius,~knobPos[1,3].value,\effectOut,~effectBus])}.defer(0.2);
		{~knobPos[2,5] = Synth.after(~frogSynth,\positioner, [\inBus, ~frogBus,\mainOut,0,\angle,~knobPos[2,2].value.linlin(0,1,-1,1),\radius,~knobPos[2,3].value,\effectOut,~effectBus])}.defer(0.2);
		{~knobPos[3,5] = Synth.after(~stepSynth,\positioner, [\inBus, ~stepBus,\mainOut,0,\angle,~knobPos[3,2].value.linlin(0,1,-1,1),\radius,~knobPos[3,3].value,\effectOut,~effectBus])}.defer(0.2);


		//creation of main stereo meters

		~meterL = LevelIndicator.new(w5, Rect(50,327,30,sectWinHeight-30))
		.background_(Color.fromHexString("#028090"))
		.warning_(0.6)
		.drawsPeak_(true)
		.meterColor_(Color.fromHexString("#78cdd7"))
		.warningColor_(Color.fromHexString("#258de8"))
		.criticalColor_(Color.fromHexString("#02427a"))
		.critical_(0.8)
		.numTicks_(0)
		.style_(\led)
		.numSteps_(20);

		~meterR = LevelIndicator.new(w5, Rect(85,327,30,sectWinHeight-30))
		.background_(Color.fromHexString("#028090"))
		.warning_(0.6)
		.drawsPeak_(true)
		.meterColor_(Color.fromHexString("#78cdd7"))
		.warningColor_(Color.fromHexString("#258de8"))
		.criticalColor_(Color.fromHexString("#02427a"))
		.critical_(0.8)
		.numTicks_(0)
		.style_(\led)
		.numSteps_(20);

		//control bus to send periodic amplitude level to the stereo meters

		~krBus = Bus.control(s,2);
		{~stereoMonitor = Synth.after(~stereoMaster,\stereoMonitor,[\inBus,0,\krBus,~krBus]);
			~updateIndicator = fork{loop{
				~krBus.get({
					arg value;
					{
						//value[0].postln;
						~meterL.value_(value[0]);
						~meterR.value_(value[1]);
						//~meter.peakLevel_(value[0]);
					}.defer();
				});
				0.01.wait;
			}
		};}.defer(0.5);

		//scope%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		~bufFire = Buffer.alloc(s, 1024, 1);
		~scopefire = ScopeView(w1, Rect(275,35, 150, 60)).resize_(5).style_(0).fill_(false).waveColors = [Color.fromHexString("#78cdd7"), Color.green];
		~scopefire.bufnum = ~bufFire.bufnum;
		~scopefire.server_(s);
		~scopefire.start;

		~bufWolf = Buffer.alloc(s, 1024, 1);
		~scopewolf = ScopeView(w2, Rect(275,35, 150, 60)).resize_(5).style_(0).fill_(false).waveColors = [Color.fromHexString("#78cdd7"), Color.green];
		~scopewolf.bufnum = ~bufWolf.bufnum;
		~scopewolf.server_(s);
		~scopewolf.start;

		~bufFrog = Buffer.alloc(s, 1024, 1);
		~scopefrog = ScopeView(w3, Rect(275,35, 150, 60)).resize_(5).style_(0).fill_(false).waveColors = [Color.fromHexString("#78cdd7"), Color.green];
		~scopefrog.bufnum = ~bufFrog.bufnum;
		~scopefrog.server_(s);
		~scopefrog.start;

		~bufStep = Buffer.alloc(s, 1024, 1);
		~scopestep = ScopeView(w4, Rect(275,35, 150, 60)).resize_(5).style_(0).fill_(false).waveColors = [Color.fromHexString("#78cdd7"), Color.green];
		~scopestep.bufnum = ~bufStep.bufnum;
		~scopestep.server_(s);
		~scopestep.start;



		//panner---------------------------------------------------------------------------
		for (0, (numOfPoints-1), {
			arg i;
			var angle, distance;

			angle = ~knobPos[i,2].value.linlin(0,1,(-pi/2),(pi/2));

			distance = ~knobPos[i,3].value.linlin(0,1,0,(height-10));

			x = (((distance*((angle).sin))+centerPosX));
			y = ((((height-10)-(distance*(angle).cos))));
			~knobPos[i,0] = x;
			~knobPos[i,1] = y;
		};
		);



		//function to create the panner view

		~wpFunc = {
			//.background_(Color.rand)
			~wp = Window.new("spanner", Rect(panWinRL,panWinUpDown,panWinWidth,panWinHeight+18), false)
			.front
			.alwaysOnTop_(false)
			.visible_(false)
			.drawFunc_({});
			v = UserView(~wp,Rect(0,0,width,height+18));


			//function to draw the elements in the panner view
			v.drawFunc = {
				Pen.addRect(~wp.view.bounds.insetBy(0))
				.fillRadialGradient( (panWinWidth/2)@(panWinHeight),(panWinWidth/2)@(panWinHeight),80,600,
					Color.fromHexString("#05668d"), Color.fromHexString("#78cdd7"))
				//.addOval(Rect((panWinWidth/2)-20,panWinHeight-20,40,40))
				.color_(Color.white)
				.fill
				//i1.tileInRect(Rect(marg,marg,120,120),nil,2,1.0);
				.addArc((panWinWidth/2)@(panWinHeight),25,pi,2pi)

				.fill
				.addArc((panWinWidth/2)@(panWinHeight),(height-10),pi,2pi)
				.alpha_(0.8)
				.stroke
				.addArc((panWinWidth/2)@(panWinHeight),(height-10)/4*3,pi,2pi)
				.alpha_(0.6)
				.stroke
				.addArc((panWinWidth/2)@(panWinHeight),(height-10)/2,pi,2pi)
				.alpha_(0.4)
				.stroke
				.addArc((panWinWidth/2)@(panWinHeight),(height-10)/4,pi,2pi)
				.alpha_(0.2)
				.stroke;


				for (0, (numOfPoints-1), {
					arg i;
					var angle, distance,angle01,distance01;

					Pen.fillColor = Color.black;
					Pen.strokeColor = Color.white;


					Pen.drawImage( ((~knobPos[i,0])-18)@((~knobPos[i,1])-18), ~knobPos[i,4], operation: 'sourceOver', opacity:1);

					Pen.fillStroke;
				});
			};

			//function to select the element to move through the mouse pointer

			v.mouseDownAction = { arg view, x,y, m;

				([256, 0].includes(m)).if{ // restrict to no modifier
					//value = (x).linlin(0,v.bounds.width,0,1); v.doAction};
					var found = false;
					for (0, numOfPoints-1, {
						arg i;
						if((x>=(~knobPos[i,0]-elRadius))&&((x<=(~knobPos[i,0]+elRadius)))&&((y>=(~knobPos[i,1]-elRadius)))&&((y<=(~knobPos[i,1]+elRadius))),{
							selPos = i;
							found =true;
						});
					});
					if(found!=true,{selPos= (-1)});

				};
			};


			//function to control the movement of audio elements inside the panner view

			v.mouseMoveAction = {
				arg view, x,y, m;
				var angle,distance;
				var l = (2*(height-10));
				var h=(height-10);
				if(selPos!=(-1),{
					distance = (((((x-centerPosX).squared)+(y-centerPosY).squared).sqrt));
					angle = (((x-centerPosX)/(y-centerPosY).abs).atan);
					if(y>=height,{
						y=height;
					});
					if(distance>=1.linlin(0,1,0,height-10),{
						distance = 1.value.linlin(0,1,0,height-10);
						x = (((distance*((angle).sin))+centerPosX));
						if(y>=height,{
							y=height;
						},{
							y = (((distance-(distance*(angle).cos))));
						})

					});
					~knobPos[selPos,0] =x;
					~knobPos[selPos,1] =y;
					~knobPos[selPos,2].value_(angle.linlin(-pi/2,pi/2,0,1));
					~knobPos[selPos,3].value_(distance.linlin(0,height-10,0,1));
					~knobPos[selPos,5].set(\angle,~knobPos[selPos,2].value.linlin(0,1,-1,1));
					~knobPos[selPos,5].set(\radius,~knobPos[selPos,3].value);

					v.refresh;
					v6.refresh;

				};
				)

			};



			~wp.onClose_({
				~wpBool=false;
			});

		}.defer(0.1);

		~wpFunc.value;
		"SYSTEM STARTED...".postln;
});
)
