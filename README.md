SpriterStarling
===============

Library for playing back Spriter Animation Files (SCML)

For more detailed code examples, check out this blog post:  
http://treefortress.com/introducing-spriteras-play-spriter-animations-scml-with-starling/

Or, you can check out some of the online code Example's:  
https://github.com/treefortress/SpriterAS/tree/master/demo/src

#Dependancies
SpriterAS includes the following dependancies:
* Starling Framework (https://github.com/PrimaryFeather/Starling-Framework)
* AS3 Signals (https://github.com/robertpenner/as3-signals)

#Basic Usage

	//Load SCML File
	loader = new SpriterLoader();
	loader.completed.addOnce(onLoadComplete);
	loader.load(["assets/spriter/brawler/brawler.scml"]);

	//Playback Animation
	function onLoadComplete(loader:SpriterLoader):void {
		var brawler:SpriterClip = loader.getSpriterClip("brawler");
		brawler.x = 100;
		brawler.play("run");
		addChild(brawler);
		Starling.juggler.add(brawler);
	}

###Dynamically Adjust Playback Speed

	brawler.playbackSpeed = .5;

###Add callback's for specific events

	//Add callback @ 400ms
	brawler.addCallback(onPunch, 400)

###Swap Body Parts

	//Blink!
	brawler.swapPiece("eyes_open", "eyes_closed");
	setTimeout(function(){
		brawler.unswapPiece("eyes_open");
	}, 50)

###Tint entire sprite

	//Flash Red
	brawler.setColor(0xFF0000);

###Isolate Body Parts and control externally

	//Decapitation!
	var image:Image = brawler.getImage("brawler_head");
	brawler.excludePiece(image);

	//Position this anywhere we like, it will no longer be animated.
	image.x = 100;
	image.y = 100;

	//Return it to the animation
	brawler.includePiece(image);

###Map External Sprites to Specific Body Parts

	//Create a standard Starling Particle Emitter
	emitterFront = new PDParticleSystem(particleXml, particleTex);
	addChild(emitterFront);

	//Each frame, update the particle emitter so it appears to follow the character's hand
	public function tick(time:Number):void {
		var frontHand:Image = brawler.getImage("mage_0000_handfront");
		emitterFront.emitterX = brawler.x + frontHand.x;
		emitterFront.emitterY = brawler.y + frontHand.y;
	}