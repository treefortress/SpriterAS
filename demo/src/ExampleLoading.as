package
{
	import flash.filesystem.File;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import treefortress.spriter.AnimationSet;
	import treefortress.spriter.SpriterClip;
	import treefortress.starling.TextureLoader;
	
	public class ExampleLoading extends Sprite
	{
		[Embed(source="/assets/spriter/orc/orc.scml", mimeType="application/octet-stream")]
		public const OrcScml:Class;
		
		[Embed(source="/assets/SpriterTexturePacker.xml", mimeType="application/octet-stream")]
		public const TexturePackerXml:Class;
		
		[Embed(source="/assets/SpriterTexturePacker.png")]
		public const TexturePackerBitmap:Class;
		
		
		public function ExampleLoading(){
			
			SpriterAS_Demo.setText("Advanced Loading Example", "");
			
			var loadMethod:int = 3;
			
			//The advantage to the SpriterLoader, is that you do not need to [Embed] anything, resulting in very fast startup times on mobile.
			//If you DO want to embed the assets, there's a few ways to do this...
			
			/***************************************************
			 * Method 1 - Use TextureLoader to recursivly load all PNG's in a specific folder, but [Embed] the SCML File directly.
			 **************************************************/
			if(loadMethod == 1){
				
				var url:String = File.applicationDirectory.resolvePath("assets/spriter").url;
				TextureLoader.load(url, function(atlas:TextureAtlas) {
					//Create animation with Embedded SCML File
					var animation:AnimationSet = new AnimationSet(XML(new OrcScml()));
					//Create Character
					createSriterClip(animation, atlas);
				});
				
			}
			
			/***************************************************
			 * Method 2 - Use TextureLoader to load specific directories (Non-Recursive)
			 **************************************************/
			if(loadMethod == 2){
				
				var urls:Vector.<String> = new <String>[
					File.applicationDirectory.resolvePath("assets/spriter/brawler").url,
					File.applicationDirectory.resolvePath("assets/spriter/orc").url
				];
				TextureLoader.loadFolders(urls, function(atlas:TextureAtlas) {
					//Create animation with Embedded SCML File
					var animation:AnimationSet = new AnimationSet(XML(new OrcScml()));
					//Create Character
					createSriterClip(animation, atlas);
				});
			}
			
			/***************************************************
			 * Method 3 - Package all your textures into a TexturePacker file and [Embed] it in your project.
			 * This is probably the ideal method for web-based applications, but will result in some lengthy startUp times on mobile.
			 **************************************************/
			if(loadMethod == 3){
				
				//Create TexturePacker Atlas
				var atlas:TextureAtlas = new TextureAtlas(Texture.fromBitmap(new TexturePackerBitmap()), new XML(new TexturePackerXml()));
				//Create Animation (note that with texturePacker, you must pass the parentFolder ("orc/") into the AnimationSet
				var animation:AnimationSet = new AnimationSet(XML(new OrcScml()), 1, "orc");
				//Create Character
				createSriterClip(animation, atlas);
				
			}
		}
		
		protected function createSriterClip(animation:AnimationSet, atlas:TextureAtlas):void {
			//Create Character
			var orc:SpriterClip = new SpriterClip(animation, atlas); 
			orc.play("run");
			orc.scaleX = orc.scaleY = .5;
			addChild(orc);
			Starling.juggler.add(orc);
		}		
		
	}
}