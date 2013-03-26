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
		
		protected var ticks:int = 0;
		protected var interval:int = 5;
		
		public function Benchmark(){
			
			SpriterAS_Demo.setText("", "");
			
			//We can scale the PNG's to any size we like, allowing you to start with Hi-Res assets, and scale down to lower powered devices.
			//In this case, the source sprites are Retina-Size, so we will downscale them by 50%
			var textureScale:Number = .5;
			
			//Use the SpriterLoader class to load individual SCML files, generate a TextureAtlas, and create AnimationSets, all at once.
			spriterLoader = new SpriterLoader();
			spriterLoader.completed.addOnce(onSpriterLoaderComplete);
			
			spriterLoader.load(["http://treefortress.com/examples/SpriterAS/assets/spriter/brawler/brawler.scml"], textureScale);
			
			
		}
		
		protected function onSpriterLoaderComplete(loader:SpriterLoader):void {
			addEventListener(Event.ENTER_FRAME, function(){
				ticks++;
				//if(numChildren > 0){ return; }
				
				if(ticks % interval == 0){
					var deltaT:Number = (getTimer() - prevT)/interval;
					prevT = getTimer();
					
					var stage:Stage = SpriterAS_Demo._stage;
					
					if(deltaT < 18){
						for(var i:int = 0; i < 5; i++){
							brawler = spriterLoader.getSpriterClip("brawler");
							brawler.setPosition(
								Math.random() * (stage.stageWidth - 200), 
								Math.random() * (stage.stageHeight - 200));
							brawler.play("idle");
							addChild(brawler);
							//brawler.visible = false;
							Starling.juggler.add(brawler);
						}
					}
					SpriterAS_Demo.setText(numChildren + "", deltaT + "");
				}
				
				
			});
		}
		
	}
}