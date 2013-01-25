package
{
	
	import flash.geom.Point;
	
	import starling.animation.IAnimatable;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.PDParticleSystem;
	import starling.textures.Texture;
	
	import treefortress.spriter.SpriterClip;
	import treefortress.spriter.SpriterLoader;
	import starling.display.Image;
	
	public class ExampleMagicHands extends Sprite implements IAnimatable
	{	
		[Embed(source="/assets/particles/firehands/particle.pex", mimeType="application/octet-stream")]
		public static var particleXml:Class;
		
		[Embed(source="/assets/particles/firehands/texture.png")]
		public static var particleBitmap:Class;
		
		
		protected var spriter:SpriterClip;
		protected var loader:SpriterLoader;
		protected var dragTarget:DisplayObject;

		private var emitterFront:PDParticleSystem;
		private var emitterBack:PDParticleSystem;
		
		public function ExampleMagicHands() {
			
			SpriterAS_Demo.setText("Fire Hands", "Demonstrates how you can map other display objects to your animations. In this case, we're using 2 particle emitters, attached to the characters hands.");
			
			loader = new SpriterLoader();
			loader.completed.addOnce(onLoadComplete);
			loader.load(["assets/spriter/mage/mage.scml"], .75);
		}
		
		protected function onLoadComplete(loader:SpriterLoader):void {
			
			spriter = loader.getSpriterClip("mage");
			spriter.y = 150;
			spriter.x = 350;
			spriter.playbackSpeed = .75;
			spriter.play("run");
			Starling.juggler.add(spriter);
			addChild(spriter);
			
			emitterFront = new PDParticleSystem(new XML(new particleXml()), Texture.fromBitmap(new particleBitmap()));
			addChild(emitterFront);
			emitterFront.start();
			Starling.juggler.add(emitterFront);
			
			emitterBack = new PDParticleSystem(new XML(new particleXml()), Texture.fromBitmap(new particleBitmap()));
			addChildAt(emitterBack, 0);
			emitterBack.start();
			Starling.juggler.add(emitterBack);
			
			Starling.juggler.add(this);
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
		
		public function advanceTime(time:Number):void {
			var frontHand:Image = spriter.getImage("mage_0000_handfront");
			emitterFront.emitterX = spriter.x + frontHand.x;
			emitterFront.emitterY = spriter.y + frontHand.y;
			
			var backHand:Image = spriter.getImage("mage_0004_handback");
			emitterBack.emitterX = spriter.x + backHand.x;
			emitterBack.emitterY = spriter.y + backHand.y;
		}
		
	}
}