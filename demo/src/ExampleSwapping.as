package
{
	import flash.filesystem.File;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.TextureAtlas;
	
	import treefortress.spriter.AnimationSet;
	import treefortress.spriter.SpriterClip;
	import treefortress.spriter.SpriterLoader;
	import treefortress.starling.TextureLoader;
	
	public class ExampleSwapping extends Sprite
	{
		[Embed(source="/assets/spriter/orc/orc.scml", mimeType="application/octet-stream")]
		public const OrcScml:Class;
		
		protected var atlas:TextureAtlas;
		protected var lastTick:int = 0;
		protected var spriter:SpriterClip;
		private var loader:SpriterLoader;
		
		public function ExampleSwapping() {
			SpriterAS_Demo.setText("Swap Example", "We can make the character blink at any point in their animation cycle, simply by swapping their Eye Sprites");
			
			loader = new SpriterLoader();
			loader.completed.addOnce(onLoadComplete);
			loader.load(["assets/spriter/orc/orc.scml"], .5);
		}
		
		protected function onLoadComplete(loader:SpriterLoader):void {
			
			spriter = loader.getSpriterClip("orc");
			spriter.x = 300;
			
			spriter.playbackSpeed = 1;
			addChild(spriter);
			Starling.juggler.add(spriter);
			spriter.play("idle");
			
			//Tell the Orc to attack every little while
			setInterval(attack, 3500);
			
			//Make the sprite Blink by swapping his Eye sprites every few seconds.
			setTimeout(blink, 2000);
		}
		
		protected function attack():void {
			spriter.play("attack");
			spriter.animationComplete.addOnce(function(spriterClip:SpriterClip){
				spriter.play("idle");
			});
		}
		
		protected function blink():void {
			spriter.swapPiece("orc_0000_eyes", "orc_0000_eyes_closed");
			setTimeout(function():void {
				spriter.unswapPiece("orc_0000_eyes");
				//Sometimes blink twice
				if(Math.random() < .3){
					setTimeout(function(){ spriter.swapPiece("orc_0000_eyes", "orc_0000_eyes_closed"); }, 60);
					setTimeout(function(){ spriter.unswapPiece("orc_0000_eyes"); }, 90);
				}
				setTimeout(blink, 1000 + Math.random() * 2500);
			}, 60);	
		}
		
	}
}