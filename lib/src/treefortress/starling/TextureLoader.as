package treefortress.starling 
{
	import treefortress.utils.FileFinder;
	
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.utils.getTimer;
	
	import starling.textures.TextureAtlas;
	
	import treefortress.utils.URLImageLoader;

	public class TextureLoader
	{
		
		protected static var finder:FileFinder;
		protected static var searchDir:File;
		protected static var loaders:Vector.<URLImageLoader> = new <URLImageLoader>[];
		protected static var loadedBitmaps:Vector.<Bitmap> = new <Bitmap>[];
		
		protected static var onBuildComplete:Function;
		
		protected static var _scale:Number;
		protected static var _includeFolderName:Boolean;
		
		protected static var t:Number;
		
		public static var loadTime:int;
		
		protected static var loadStartTime:int;
		/**
		 * Loads any PNG's within the supplied directories, does not perform recursive search.
		 */
		public static function loadFolders(directoryList:Vector.<String>, onComplete, scale:Number = 1, includeFolderName:Boolean = false):void {
			_scale = scale;
			_includeFolderName = includeFolderName;
			onBuildComplete = onComplete;
			loadStartTime = getTimer();
			
			for(var i:int = 0, l:int = directoryList.length; i < l; i++){
				var dir:File = new File(directoryList[i]);
				if(dir.isDirectory && dir.exists){
					var files:Array = dir.getDirectoryListing();
					for(var j:int = files.length - 1; j >= 0; j--){
						if((files[j].type != ".png" && files[j].type != ".jpg") || files[j].isDirectory){ continue; }
						var loader:URLImageLoader = new URLImageLoader();
						loaders.push(loader);
						loader.addEventListener(Event.COMPLETE, onLoadComplete, false, 0, true);
						loader.loadImage(files[j].url);
					}
				}	
			}
		}
			
		/**
		 * Recursively searches directory, and loads any PNG's within it
		 */
		public static function load(url:String, onComplete, scale:Number = 1, includeFolderName:Boolean = false):void {
			_scale = scale;
			_includeFolderName = includeFolderName;
			
			onBuildComplete = onComplete;
			loadStartTime = getTimer();
			
			finder = new FileFinder();
			finder.addEventListener(Event.COMPLETE, function():void {
				for(var i:int = 0, l:int = finder.fileList.length; i < l; i++){
					loaders[i]  = new URLImageLoader();
					loaders[i].addEventListener(Event.COMPLETE, onLoadComplete, false, 0, true);
					loaders[i].loadImage(finder.fileList[i]);
				}
			});
			
			finder.run([url]);
			t = getTimer();
		}
		
		protected static function onLoadComplete(event:Event):void {
			var loader:URLImageLoader = (event.target as URLImageLoader);
			loader.bmpImage.name = _includeFolderName? loader.folderName + "/" + loader.fileName : loader.fileName;
			loadedBitmaps.push(loader.bmpImage);
			if(loadedBitmaps.length == loaders.length){
				buildAtlas();
			}
			
		}
		
		protected static function buildAtlas():void {
			//Build atlas
			var atlas:TextureAtlas = AtlasBuilder.buildFromBitmaps(loadedBitmaps, _scale);
			
			//var writer:ImageWriter = new ImageWriter();
			//writer.writeJPG(AtlasBuilder.textureBitmap, File.desktopDirectory.resolvePath("textures.jpg"));
			
			loadedBitmaps.length = 0;
			loaders.length = 0;
			
			loadTime = getTimer() - loadStartTime;
			trace("TextureLoader: Texture Load Complete in " + loadTime + "ms");
			if(onBuildComplete){
				onBuildComplete(atlas);
			}
		}
		
	}
}