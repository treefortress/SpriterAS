package
{
	import flash.display.Stage;
	import flash.utils.getTimer;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	import treefortress.spriter.SpriterClip;
	import treefortress.spriter.SpriterLoader;
	
	public class Benchmark extends Sprite
	{
		
		protected var brawler:SpriterClip;
		protected var spriterLoader:SpriterLoader;
		protected var orc:SpriterClip;
		
		protected var prevT:Number;
		
		public function Benchmark(){
			
			SpriterAS_Demo.setText("", "");
			
			//We can scale the PNG's to any size we like, allowing you to start with Hi-Res assets, and scale down to lower powered devices.
			//In this case, the source sprites are Retina-Size, so we will downscale them by 50%
			var textureScale:Number = .5;
			
			//Use the SpriterLoader class to load individual SCML files, generate a TextureAtlas, and create AnimationSets, all at once.
			spriterLoader = new SpriterLoader();
			spriterLoader.completed.addOnce(onSpriterLoaderComplete);
			spriterLoader.load(["assets/spriter/brawler/brawler.scml", "assets/spriter/orc/orc.scml"], textureScale);
			
			
		}
		
		protected function onSpriterLoaderComplete(loader:SpriterLoader):void {
			addEventListener(Event.ENTER_FRAME, function(){
				var deltaT:Number = getTimer() - prevT;
				prevT = getTimer();
				
				var stage:Stage = SpriterAS_Demo._stage;
				
				if(deltaT < 18 && Math.random() < .5){
					brawler = spriterLoader.getSpriterClip("brawler");
					brawler.setPosition(
						Math.random() * (stage.stageWidth - 200), 
						Math.random() * (stage.stageHeight - 200));
					brawler.play("idle");
					addChild(brawler);
					Starling.juggler.add(brawler);
					SpriterAS_Demo.setText(numChildren + "", "");
				}
				
			});
		}
		
	}
}