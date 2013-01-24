package
{
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import starling.core.Starling;
	import starling.display.Quad;
	import starling.display.Sprite;
	
	[SWF(width='700', height='350', backgroundColor="#FFFFFF")]
	public class SpriterAS_Demo extends flash.display.Sprite
	{	
		public static var _stage:flash.display.Stage;
		
		protected var _starling:Starling;
		
		public static var scaleFactor:Number = 1;
		
		protected var lastTick:int;
		protected static var title:TextField;
		protected static var desc:TextField;
		protected var bg:Quad;
		
		/**
		 * FEATURES
		 * All animations run off a single TextureAtlas
		 * TextureAtlas can easily be scaled to various screen sizes
		 * Dynamically load textures from SCML Files, Folder's, or from TexturePacker
		 * Swap parts mid-animation (eyes > eyes_blink, sword_1 > sword_2)
		 * Control playback speed independant of stage framerate
		 */
		
		public function SpriterAS_Demo(){
			
			SpriterAS_Demo._stage = stage;
			_stage.scaleMode = StageScaleMode.NO_SCALE;
			_stage.align = StageAlign.TOP_LEFT;
			_stage.frameRate = 60;
			
			setTimeout(function(){
				initStarlng();
			}, 250);
			lastTick = getTimer();
		}
	
		protected function initStarlng():void {
			_starling = new Starling(starling.display.Sprite, stage);
			_starling.showStats = true;
			_starling.start();
			_starling.addEventListener("rootCreated", function(){
				
				initText();
				initDemo();
				
			});
		}
		
		protected function initDemo():void {
			var root:Sprite = Starling.current.root as Sprite;
			
			//Simple demo showing the different method to loading a Spriter animation
			//root.addChild(new ExampleBasic());
			
			//Swap-Demo, showing a dynamic blink animation
			//root.addChild(new ExampleSwapping());
			
			//Callback / Event demo
			//root.addChild(new ExampleCallback());
			
			//Drag and Drop Example
			//root.addChild(new ExampleDragAndDrop());
			
			//Follow Piece
			root.addChild(new ExampleMagicHands());
			
			//root.addChild(new Debug());
			
			
		}
		
		protected function initText():void {
			title = new TextField();
			title.defaultTextFormat = new TextFormat("Arial", 24, 0x0, true, null, null, null, null, "center");
			title.width = _stage.stageWidth;
			title.mouseEnabled = title.selectable = false;
			addChild(title);
			
			desc = new TextField();
			desc.defaultTextFormat = new TextFormat("Arial", 12, 0x0, false, null, null, null, null, "center");
			desc.width = _stage.stageWidth;
			desc.y =  _stage.stageHeight - 50;
			desc.multiline = true;
			desc.wordWrap = true;
			desc.mouseEnabled = desc.selectable = false;
			addChild(desc);
		}
		
		public static function setText(titleText:String = "", descText:String = ""):void {
			title.text = titleText;
			desc.text = descText;
		}
	}
}