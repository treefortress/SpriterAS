package
{
	import com.bit101.components.HUISlider;
	
	import flash.utils.setTimeout;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.textures.TextureAtlas;
	
	import treefortress.spriter.SpriterClip;
	import treefortress.spriter.SpriterLoader;
	
	public class ExampleCallback extends Sprite
	{
		[Embed(source="/assets/spriter/orc/orc.scml", mimeType="application/octet-stream")]
		public const OrcScml:Class;
		
		protected var atlas:TextureAtlas;
		protected var lastTick:int = 0;
		protected var spriter:SpriterClip;

		protected var speedSlider:HUISlider;
		protected var startX:Number = 250;
		protected var startY:Number = 0;
		private var loader:SpriterLoader;
		
		public function ExampleCallback() {
			
			SpriterAS_Demo.setText("Callback Example", "Add a callback each time a foot touches the ground, and programtically 'shake' the character. \nNotice that this works independant of playback speed.");
			
			loader = new SpriterLoader();
			loader.completed.addOnce(onLoadComplete);
			loader.load(["assets/spriter/orc/orc.scml"], .5);
		}
		
		protected function onLoadComplete(loader:SpriterLoader):void {
			
			spriter = new SpriterClip(loader.getAnimationSet("orc"), loader.textureAtlas); 
			spriter.x = startX;
			spriter.y = startY;
			spriter.play("run");
			Starling.juggler.add(spriter);
			addChild(spriter);
			
			//To determing when an animation has completed, just listen for the animationComplete signal.
			spriter.animationComplete.add(function(clip:SpriterClip) {
				trace("animationComplete");
			});
			
			//To respond an specific timed events, add a custom callback:
			spriter.addCallback(function() { 
				trace("left Foot"); 
				shakeSprite(3);
			}, 840, false); //Callback @ 840ms
			
			spriter.addCallback(function() { 
				trace("Right Foot"); 
				shakeSprite(6);
			}, 400, false); //Callback @ 400ms
			
			//Add slider to adjust playback speed
			speedSlider = new HUISlider(SpriterAS_Demo._stage, 100, 220, "Playback Speed", onSpeedChanged);
			speedSlider.minimum = .01;
			speedSlider.maximum = 3;
			speedSlider.value = .25;
			speedSlider.setSize(500, speedSlider.height);
			SpriterAS_Demo._stage.addChild(speedSlider);
			onSpeedChanged();
		}
		
		protected function onSpeedChanged(event:* = null):void {
			spriter.playbackSpeed = speedSlider.value;
		}
		
		protected function shakeSprite(amount:int):void {
			for(var i:int = 0; i < amount; i++){
				setTimeout(function(){
					spriter.x = startX - 5 + 10 * Math.random();
					spriter.y = -5 + 10 * Math.random();
				}, i * 34);
			}
			setTimeout(function(){
				spriter.x = startX;
				spriter.y = 0;
			}, i * 34);
		}
	}
}