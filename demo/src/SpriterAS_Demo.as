package
{
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.setTimeout;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	
	[SWF(width='700', height='350', backgroundColor="#FFFFFF")]
	public class SpriterAS_Demo extends flash.display.Sprite
	{	
		public static var _stage:flash.display.Stage;
		protected var _starling:Starling;
		
		protected static var title:TextField;
		protected static var desc:TextField;
		
		protected var currentExample:Class;
		
		public function SpriterAS_Demo(){
			
		//Bootstrap	
			SpriterAS_Demo._stage = stage;
			_stage.scaleMode = StageScaleMode.NO_SCALE;
			_stage.align = StageAlign.TOP_LEFT;
			_stage.frameRate = 60;
			setTimeout(initStarlng, 250);
			
			setTimeout(function(){
				DisplayObjectContainer.checkBroadcastListener = false;
			}, 2000);
			
		//Choose Example:
			
			//Simple demo showing the different method to loading a Spriter animation
			currentExample = ExampleBasic;
			//currentExample = Benchmark;
			//Swap-Demo, showing a dynamic blink animation
			//currentExample = ExampleSwapping;
			
			//Callback / Trigger Event demo
			//currentExample = ExampleCallback;
			
			//Drag and Drop Example
			//currentExample = ExampleDragAndDrop;
			
			//Map external display objects to specific body-parts
			//currentExample = ExampleMagicHands;
			
			//Advanced loading techniques
			//currentExample = ExampleLoading;
		}
	
		protected function initStarlng():void {
			_starling = new Starling(starling.display.Sprite, stage);
			_starling.showStats = true;
			_starling.start();
			_starling.addEventListener("rootCreated", function(){
				initText();
				
				var root:Sprite = Starling.current.root as Sprite;
				root.addChild(new currentExample());
			});
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