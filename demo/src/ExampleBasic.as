package
{
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	import treefortress.spriter.SpriterClip;
	import treefortress.spriter.SpriterLoader;
	
	public class ExampleBasic extends Sprite
	{
		
		protected var brawler:SpriterClip;
		protected var spriterLoader:SpriterLoader;
		protected var orc:SpriterClip;
		
		public function ExampleBasic(){
			
			SpriterAS_Demo.setText("Basic Example", "Click Each Character to make them Attack");
			
			//We can scale the PNG's to any size we like, allowing you to start with Hi-Res assets, and scale down to lower powered devices.
			//In this case, the source sprites are Retina-Size, so we will downscale them by 50%
			var textureScale:Number = .5;
			
			//Use the SpriterLoader class to load individual SCML files, generate a TextureAtlas, and create AnimationSets, all at once.
			spriterLoader = new SpriterLoader();
			spriterLoader.completed.addOnce(onSpriterLoaderComplete);
			spriterLoader.load(["assets/spriter/imp/imp.scml", "assets/spriter/brawler/brawler.scml"], textureScale);
		}
		
		protected function onSpriterLoaderComplete(loader:SpriterLoader):void {
			
			//Add Orc 1
			orc = spriterLoader.getSpriterClip("imp");
			orc.play("run", 0);
			orc.scaleX = -1;
			orc.y = 50;
			orc.x = 300;
			orc.playbackSpeed = .1;
			addChild(orc);
			
			//For performance reasons, SpriterClips will not update themselves, they must externally ticked each frame. 
			//The Starling Juggler is a simple way to do that.
			Starling.juggler.add(orc);
			
			//Add a "Brawler"
			brawler = spriterLoader.getSpriterClip("brawler");
			brawler.setPosition(500, 50);
			brawler.play("idle");
			addChild(brawler);
			Starling.juggler.add(brawler);
			
			//Add Touch Support to each Sprite
			orc.touchable = true;
			orc.addEventListener(TouchEvent.TOUCH, onCharacterTouched);
			brawler.touchable = true;
			brawler.addEventListener(TouchEvent.TOUCH, onCharacterTouched);
			
		}
		
		protected function onCharacterTouched(event:TouchEvent):void {
			var touch:Touch = event.touches[0];
			if(touch.phase == TouchPhase.ENDED){
				(event.currentTarget as SpriterClip).play("dead2");
				(event.currentTarget as SpriterClip).animationComplete.addOnce(function(clip:SpriterClip){
					clip.play((clip == brawler)? "idle" : "run");
				});
			}
		}
	}
}