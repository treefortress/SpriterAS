package
{
	
	import flash.geom.Point;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	import treefortress.spriter.SpriterClip;
	import treefortress.spriter.SpriterLoader;
	
	public class ExampleDragAndDrop extends Sprite
	{		
		protected var spriter:SpriterClip;
		protected var loader:SpriterLoader;
		protected var dragTarget:DisplayObject;
		
		public function ExampleDragAndDrop() {
			
			SpriterAS_Demo.setText("Drag and Drop", "Click on any of the character's part's to begin dragging it. \nDemonstrates the ability to control specific body-parts outside of the animation. \nThis would allow for dismemberment (ala Plants vs Zombies).");
			
			loader = new SpriterLoader();
			loader.completed.addOnce(onLoadComplete);
			loader.load(["assets/spriter/brawler/brawler.scml"], .75);
		}
		
		protected function onLoadComplete(loader:SpriterLoader):void {
			
			spriter = new SpriterClip(loader.getAnimationSet("brawler"), loader.textureAtlas); 
			spriter.x = 200;
			spriter.play("run");
			Starling.juggler.add(spriter);
			addChild(spriter);
			
			//For performance reasons, SpriterClip's are not touchable by default.
			spriter.touchable = true;
			spriter.addEventListener(TouchEvent.TOUCH, onSpriteTouched);
		}
		
		protected function onSpriteTouched(event:TouchEvent):void {
			var target:DisplayObject = event.target as DisplayObject; 
			var touch:Touch = event.touches[0];
			
			//User Has Pressed on a Piece
			if(touch.phase == TouchPhase.BEGAN){
				dragTarget = target;
				spriter.excludePiece(target, true);
			}
			//User has released a piece
			else if(touch.phase == TouchPhase.ENDED){
				dragTarget = null;
				spriter.excludePiece(target, false);
			} 
			//User has moved the mouse while a piece is being dragged
			else if(dragTarget && touch.phase == TouchPhase.MOVED){
				//Convert global X/Y to local
				var pt:Point = spriter.globalToLocal(new Point(touch.globalX, touch.globalY));
				dragTarget.x = pt.x;
				dragTarget.y = pt.y;
			}
			
		}
	}
}