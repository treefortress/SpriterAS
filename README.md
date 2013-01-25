SpriterStarling
===============

Library for playing back Spriter Animation Files (SCML)

##Basic Usage

	//Load SCML File
	loader = new SpriterLoader();
	loader.completed.addOnce(onLoadComplete);
	loader.load(["assets/spriter/brawler/brawler.scml"]);

	//Playback Animation
	function onLoadComplete(loader:SpriterLoader):void {
		var brawler:SpriterClip = loader.getSpriterClip("brawler");
		brawler.play("run");
		addChild(brawler);
		Starling.juggler.add(brawler);
	}

