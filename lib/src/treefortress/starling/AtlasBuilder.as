package treefortress.starling
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	public class AtlasBuilder
	{
		public static var packTime:int;
		public static var atlasBitmap:BitmapData;
		public static var atlasXml:XML;
		
		public function AtlasBuilder(){
		}
		
		public static function buildFromBitmaps(bitmapList:Vector.<Bitmap>, scale:Number = 1, padding:int = 2, width:int = 2048, height:int = 2048):TextureAtlas {
			
			var t:int = getTimer();
			
			atlasBitmap = new BitmapData(width, height, true, 0x0);
			var packer:MaxRectPacker = new MaxRectPacker(width, height);
			var atlasText:String = "";
			var bitmap:Bitmap, name:String, rect:Rectangle, subText:String, m:Matrix = new Matrix();
			
			for(var i:int = 0; i < bitmapList.length; i++){
				bitmap = bitmapList[i];
				name = bitmapList[i].name;
				rect = packer.quickInsert((bitmap.width * scale) + padding * 2, (bitmap.height * scale) + padding * 2);
				
				//Add padding
				rect.x += padding;
				rect.y += padding;
				rect.width -= padding * 2;
				rect.height -= padding * 2;
				
				//Apply scale
				if(!rect){ trace("Texture Limit Exceeded"); continue; }
				m.identity();
				m.scale(scale, scale);
				m.translate(rect.x, rect.y);
				atlasBitmap.draw(bitmapList[i].bitmapData, m, null, null, null, true);
				
				//Create XML line item for TextureAtlas
				subText = '<SubTexture name="'+name+'" ' +
					'x="'+rect.x+'" y="'+rect.y+'" width="'+rect.width+'" height="'+rect.height+'" frameX="0" frameY="0" ' +
					'frameWidth="'+rect.width+'" frameHeight="'+rect.width+'"/>';
				atlasText = atlasText + subText;
			}
			
			//Create XML from text (much faster than working with an actual XML object)
			atlasText = '<TextureAtlas imagePath="atlas.png">' + atlasText + "</TextureAtlas>";
			atlasXml = new XML(atlasText);
			
			//Create the atlas
			var texture:Texture = Texture.fromBitmapData(atlasBitmap, false);
			var atlas:TextureAtlas = new TextureAtlas(texture, atlasXml);
			
			//Save elapsed time in case we're curious how long this took
			packTime = getTimer() - t;
			
			return atlas;
		}
	}
}