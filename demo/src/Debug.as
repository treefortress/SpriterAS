package
{
	import flash.filesystem.File;
	import flash.utils.getTimer;
	
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.TextureAtlas;
	
	import treefortress.spriter.AnimationSet;
	import treefortress.spriter.SpriterClip;
	import treefortress.starling.TextureLoader;
	
	public class Debug extends Sprite
	{
		[Embed(source="/assets/spriter/orc/orc.scml", mimeType="application/octet-stream")]
		public const OrcScml:Class;
		
		protected var atlas:TextureAtlas;
		protected var lastTick:int = 0;
		protected var spriter:SpriterClip;
		protected var spriter2:SpriterClip;
		
		public function Debug() {
			var url:String = File.applicationDirectory.resolvePath("assets/spriter").url;
			TextureLoader.load(url, onTexturesComplete, 1);
		}
		
		protected function onTexturesComplete(atlas:TextureAtlas):void {
			
			this.atlas = atlas;
			var anim:AnimationSet = new AnimationSet(XML(new OrcScml()), 1);
			
			spriter = new SpriterClip(anim, atlas); 
			spriter.x = 0;
			spriter.y = 0;
			spriter.play("dead");
			spriter.playbackSpeed = .5;
			addChild(spriter);
			
			addFrameListener();
		}
		
		protected function addFrameListener():void {
			lastTick = getTimer();
			addEventListener(Event.ENTER_FRAME, function update():void {
				var elapsed:int = getTimer() - lastTick;
				lastTick = getTimer();
				spriter.update(elapsed);
			});
		}
	}
}