package
{
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import treefortress.spriter.AnimationSet;
	import treefortress.spriter.SpriterClip;
	import treefortress.spriter.SpriterLoader;
	import treefortress.spriter.SpriterSprite;
	import treefortress.starling.AtlasBuilder;
	
	public class ExampleBasic extends Sprite
	{
		[Embed(source="/assets/spriter/orc/orc.scml", mimeType="application/octet-stream")]
		public const OrcScml:Class;
		
		[Embed(source="/assets/SpriterTexturePacker.xml", mimeType="application/octet-stream")]
		public const TexturePackerXml:Class;
		
		[Embed(source="/assets/SpriterTexturePacker.png")]
		public const TexturePackerBitmap:Class;
		
		protected var lastTick:int = 0;
		protected var atlas:TextureAtlas;

		private var orcAnim:AnimationSet;

		protected var textureScale:Number;

		private var spriterLoader:SpriterLoader;
		
		public function ExampleBasic(){
			
			SpriterAS_Demo.setTitle("Basic Example: Click Each Character to make them Attack");
			
			//We can scale the PNG's to any size we like, allowing you to start with Hi-Res assets, and scale down to lower powered devices.
			textureScale = .5;
			
			/**
			 * To start load the textures (png's) and SCML (xml) files. 
			 * There are a few different ways to do this.
			 */
			
			//OPTION 1
			//Use the SpriterLoader class to load individual SCML files, generate Atlas, and create AnimationSets, all at once!
			spriterLoader = new SpriterLoader();
			spriterLoader.completed.addOnce(function(loader:SpriterLoader){
				//Once SpriterLoader is complete, we can simply retrieve the AnimationSet and TextureAtlas
				atlas = spriterLoader.textureAtlas;
				orcAnim = spriterLoader.getAnimationSet("orc");
				startDemo();
			});
			spriterLoader.load(["assets/spriter/brawler/brawler.scml", "assets/spriter/orc/orc.scml"], textureScale);
			
			//OPTION 2
			//Create the TextureAtlas yourself, and create the AnimationSet with an embedded XML File.
			//There's a few ways to do this.
			
			//2A - Recursive Image Search, adds all images to textureAtlas and returns it.
			/*
			var url:String = File.applicationDirectory.resolvePath("assets/spriter").url;
			TextureLoader.load(url, onTexturesComplete, textureScale);
			*/
			
			//2B - Non-Recursive Image Search, adds all images to textureAtlas and returns it.
			/*
			var urls:Vector.<String> = new <String>[
			File.applicationDirectory.resolvePath("assets/spriter/brawler").url,
			File.applicationDirectory.resolvePath("assets/spriter/orc").url
			];
			TextureLoader.loadFolders(urls, onTexturesComplete, textureScale);
			*/
			
			//2C - Load from embedded TexturePacker File. 
			/*
			atlas = new TextureAtlas(Texture.fromBitmap(new TexturePackerBitmap(), false, false, 1/textureScale), new XML(new TexturePackerXml()));
			onTexturesComplete(atlas, true);
			*/
			
			//title = SpriterStarling.title;
		}
		
		protected function onSpriterLoaderCompleted():void {
			
		}
		
		
		protected function onTexturesComplete(atlas:TextureAtlas, addPrefix:Boolean = false):void {
			
			// Once textures have loaded, we'll get back our texture atlas
			this.atlas = atlas;
			
			//And we can now create a unit....
			//First we need an AnimationSet, this should be resued by all Instances of the same Animation
			orcAnim = new AnimationSet(XML(new OrcScml()), textureScale);
			
			//If using texturePacker, we need to pass the folder name to the animationSet, so it can properly retrieve the textures.
			if(addPrefix){ orcAnim.prefix = "orc/"; }
			
			startDemo();
			
		}
		
		protected function startDemo():void {
			
			//Add Orc 1
			var spriter:SpriterClip = new SpriterClip(orcAnim, atlas); 
			spriter.play("run");
			spriter.scaleX = -1;
			spriter.y = 10;
			spriter.x = 300;
			addChild(spriter);
			//Our animations will not update themselves, they must be ticked each frame. 
			//The Starling Juggler is the easiest way to do that.
			Starling.juggler.add(spriter);
			
			//Add a "Brawler"
			var brawler:SpriterClip = new SpriterClip(spriterLoader.getAnimationSet("brawler"), atlas);
			brawler.x = 500;
			brawler.y = 50;
			brawler.play("idle");
			addChild(brawler);
			Starling.juggler.add(brawler);
			
			
			
			if(AtlasBuilder.atlasBitmap){
				var image:Image = new Image(Texture.fromBitmapData(AtlasBuilder.atlasBitmap));
				image.y = 300;
				//addChild(image);
			}
		}
	}
}