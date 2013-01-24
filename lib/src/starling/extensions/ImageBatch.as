package starling.extensions 
{
	import com.adobe.utils.AGALMiniAssembler;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.errors.MissingContextError;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.VertexData;
	
	/**
	 * Animate a lot of elements as one batched call to the GPU.
	 *
	 * @author Philippe / http://philippe.elsass.me
	 */
	public class ImageBatch extends DisplayObject 
	{
		public var blendFactorSource:String;
		public var blendFactorDest:String;

		private var _drawCount:int;
		private var _texture:Texture;
		private var _clonedItems:Vector.<BatchItem>;
		
		private var items:Vector.<BatchItem>;
		private var vertexData:VertexData;
		private var indices:Vector.<uint>;
		private var vertexBuffer:VertexBuffer3D;
		private var indexBuffer:IndexBuffer3D;
		private var premultipliedAlpha:Boolean;
		private var alphaVector:Vector.<Number>;
		private var baseVertexData:VertexData;
		private var defaultVertexData:VertexData;
		private var atlasVertexData:Dictionary = new Dictionary();
		private var smoothing:String;
		
		public function ImageBatch(texture:Texture, smoothing:String = TextureSmoothing.BILINEAR, blendFactorSource:String = null, blendFactorDest:String = null)
		{
			this.blendFactorDest = blendFactorDest;
			this.blendFactorSource = blendFactorSource;
			this.smoothing = smoothing;
			this.texture = texture;
			
			items = new Vector.<BatchItem>();
			vertexData = new VertexData(0, premultipliedAlpha);
			indices = new <uint>[];
			
			registerPrograms(Starling.current);
		}
		
		public function registerPrograms(target:Starling):void
        {
            // create vertex and fragment programs - from assembly.
            // each combination of repeat/mipmap/smoothing has its own fragment shader.
            
            var vertexProgramCode:String =
                "m44 op, va0, vc0  \n" +  // 4x4 matrix transform to output clipspace
                "mov v0, va1       \n" +  // pass color to fragment program
                "mov v1, va2       \n";   // pass texture coordinates to fragment program

            var fragmentProgramCode:String =
                "tex ft1, v1, fs1 <???> \n" +  // sample texture 1
                "mul ft2, ft1, v0       \n" +  // multiply color with texel color
                "mul oc, ft2, fc0       \n";   // multiply color with alpha

            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);
            
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            
            var smoothingTypes:Array = [
                TextureSmoothing.NONE,
                TextureSmoothing.BILINEAR,
                TextureSmoothing.TRILINEAR
            ];
            
            for each (var repeat:Boolean in [true, false])
            {
                for each (var mipmap:Boolean in [true, false])
                {
                    for each (var smoothing:String in smoothingTypes)
                    {
                        var options:Array = ["2d", repeat ? "repeat" : "clamp"];
                        
                        if (smoothing == TextureSmoothing.NONE)
                            options.push("nearest", mipmap ? "mipnearest" : "mipnone");
                        else if (smoothing == TextureSmoothing.BILINEAR)
                            options.push("linear", mipmap ? "mipnearest" : "mipnone");
                        else
                            options.push("linear", mipmap ? "miplinear" : "mipnone");
                        
                        fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT,
                            fragmentProgramCode.replace("???", options.join())); 
                        
                        target.registerProgram(getProgramName(mipmap, repeat, smoothing),
                            vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
                    }
                }
            }
        }
		
		public function addItem():BatchItem
		{
			var item:BatchItem;
			if (_drawCount < items.length) 
			{
				item = items[_drawCount];
				item.x = item.y = 0;
				item.color = 0xffffff;
				item.alpha = item.scale = 1;
			}
			else 
			{
				item = new BatchItem(this);
				items.fixed = false;
				indices.fixed = false;
				var vertexID:int = _drawCount << 2;
				var verticeID:int = _drawCount << 2;
				vertexData.append(defaultVertexData);
				indices.push(verticeID,     verticeID + 1, verticeID + 2, 
							 verticeID + 1, verticeID + 3, verticeID + 2);
				items.push(item);
				items.fixed = true;
				indices.fixed = true;
			}
			_drawCount++;
            if (vertexBuffer) { vertexBuffer.dispose(); vertexBuffer = null; }
            if (indexBuffer)  { indexBuffer.dispose(); indexBuffer = null; }
			return item;
		}
		
		public function removeItem(item:BatchItem):void
		{
			var index:int = items.indexOf(item);
			if (index < 0) return;
			_drawCount--;
			items[index] = items[_drawCount];
			items[index].dirty = 3;
			items[_drawCount] = item;
		}
		
		public function removeItemAt(index:int):void
		{
			if (_drawCount <= index) return;
			_drawCount--;
			var item:BatchItem = items[index];
			items[index] = items[_drawCount];
			items[index].dirty = 3;
			items[_drawCount] = item;
		}
        
        public override function dispose():void
        {
            if (vertexBuffer) { vertexBuffer.dispose(); vertexBuffer = null; }
            if (indexBuffer)  { indexBuffer.dispose(); indexBuffer = null; }
			_texture = null;
			defaultVertexData = null;
			items = null;
            
            super.dispose();
        }
		
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            var matrix:Matrix = getTransformationMatrix(targetSpace);
            var position:Point = matrix.transformPoint(new Point(x, y));
            return new Rectangle(position.x, position.y);
        }
		
		public override function render(support:RenderSupport, alpha:Number):void
        {
            if (_drawCount == 0) return;
			
            var item:BatchItem, vOffset:int, cOffset:int, uOffset:int, 
				x:Number, y:Number, s:Number, tw2:Number, th2:Number, 
				ca:Number, sa:Number, ox1:Number, ox2:Number, oy1:Number, oy2:Number;
			var tex:Texture = texture, itex:Texture;
            var textureWidth:Number = tex.width, textureHeight:Number = tex.height;
			var data:Vector.<Number> = vertexData.rawData;
			const EPV:int = VertexData.ELEMENTS_PER_VERTEX;
			const EPV2:int = VertexData.ELEMENTS_PER_VERTEX * 2;
			const EPV3:int = VertexData.ELEMENTS_PER_VERTEX * 3;
			const COL:int = VertexData.COLOR_OFFSET;
			const TEX:int = VertexData.TEXCOORD_OFFSET;
			
			for (var i:int = 0; i < _drawCount; ++i)
            {
                item = items[i];
				
                vOffset = (i << 2) * EPV;
                x = item.x;
                y = item.y;
                s = item.scale;
				
				itex = item.texture;
				if (itex && itex != tex)
				{
					tex = itex;
					textureWidth = tex.width;
					textureHeight = tex.height;
				}
                tw2 = textureWidth  * s >> 1;
                th2 = textureHeight * s >> 1;
				
				if (item.dirty)
				{
					if ((item.dirty & 2) > 0)
					{
						if (!(itex in atlasVertexData)) 
						{
							var vData:VertexData = baseVertexData.clone();
							itex.adjustVertexData(vData, 0, 4);
							atlasVertexData[itex] = vData;
						}
						var tdata:Vector.<Number> = atlasVertexData[itex].rawData;
						uOffset = vOffset + TEX;
						var tOffset:int = TEX;
						data[int(uOffset)]     = tdata[int(tOffset)];
						data[int(uOffset + 1)] = tdata[int(tOffset + 1)];
						tOffset += EPV;
						data[int(uOffset + EPV)]     = tdata[int(tOffset)];
						data[int(uOffset + EPV + 1)] = tdata[int(tOffset + 1)];
						tOffset += EPV;
						data[int(uOffset + EPV2)]     = tdata[int(tOffset)];
						data[int(uOffset + EPV2 + 1)] = tdata[int(tOffset + 1)];
						tOffset += EPV;
						data[int(uOffset + EPV3)]     = tdata[int(tOffset)];
						data[int(uOffset + EPV3 + 1)] = tdata[int(tOffset + 1)];
					}
					
					// color/alpha
					cOffset = vOffset + COL;
					
					//var k:Number = (premultipliedAlpha ? item.alpha : 1) / 255; <- memory exploding! Oo
					var k:Number = (premultipliedAlpha ? item.alpha : 1);
					k /= 255;
					
					data[cOffset] = data[int(cOffset + EPV)] = data[int(cOffset + EPV2)] = data[int(cOffset + EPV3)]
						= (item.color >> 16) * k;
					++cOffset;
					data[cOffset] = data[int(cOffset + EPV)] = data[int(cOffset + EPV2)] = data[int(cOffset + EPV3)] 
						= ((item.color >> 8) & 0xff) * k;
					++cOffset;
					data[cOffset] = data[int(cOffset + EPV)] = data[int(cOffset + EPV2)] = data[int(cOffset + EPV3)] 
						= (item.color & 0xff) * k;
					++cOffset;
					data[cOffset] = data[int(cOffset + EPV)] = data[int(cOffset + EPV2)] = data[int(cOffset + EPV3)] 
						= item.alpha;
					++cOffset;
					item.dirty = 0;
				}
				
				if (item.angle)
				{
					ca = Math.cos(item.angle);
					sa = Math.sin(item.angle);
					ox1 = tw2 * ca + th2 * sa;
					ox2 = tw2 * ca - th2 * sa;
					oy1 = -tw2 * sa + th2 * ca;
					oy2 = tw2 * sa + th2 * ca;
					data[int(vOffset)] 	          = x - ox1;
					data[int(vOffset + 1)]        = y - oy1;
					data[int(vOffset + EPV)]      = x + ox2;
					data[int(vOffset + EPV + 1)]  = y - oy2;
					data[int(vOffset + EPV2)]     = x - ox2;
					data[int(vOffset + EPV2 + 1)] = y + oy2;
					data[int(vOffset + EPV3)]     = x + ox1;
					data[int(vOffset + EPV3 + 1)] = y + oy1;
				}
				else 
				{
					data[int(vOffset)]            = x - tw2;
					data[int(vOffset + 1)] 	      = y - th2;
					data[int(vOffset + EPV)]      = x + tw2;
					data[int(vOffset + EPV + 1)]  = y - th2;
					data[int(vOffset + EPV2)]     = x - tw2;
					data[int(vOffset + EPV2 + 1)] = y + th2;
					data[int(vOffset + EPV3)]     = x + tw2;
					data[int(vOffset + EPV3 + 1)] = y + th2;
				}
            }
			
            alpha *= this.alpha;

            var program:String = getProgramName(texture.mipMapping, false, smoothing);
            var context:Context3D = Starling.context;
            
            if (context == null) throw new MissingContextError();
            
			if (vertexBuffer == null)
			{
				vertexBuffer = context.createVertexBuffer(items.length * 4, VertexData.ELEMENTS_PER_VERTEX);
				indexBuffer = context.createIndexBuffer(items.length * 6);
			}
            vertexBuffer.uploadFromVector(vertexData.rawData, 0, items.length * 4);
            indexBuffer.uploadFromVector(indices, 0, items.length * 6);
            
			var blendDest:String = blendFactorDest || Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            var blendSource:String = blendFactorSource ||
                (premultipliedAlpha ? Context3DBlendFactor.ONE : Context3DBlendFactor.SOURCE_ALPHA);
            context.setBlendFactors(blendSource, blendDest);
            
			var programTmp:Program3D = Starling.current.getProgram(program);
			
            context.setProgram(programTmp);
            context.setTextureAt(1, texture.base);
            context.setVertexBufferAt(0, vertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3); 
            context.setVertexBufferAt(1, vertexBuffer, VertexData.COLOR_OFFSET,    Context3DVertexBufferFormat.FLOAT_4);
            context.setVertexBufferAt(2, vertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix3D, true);            
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, alphaVector, 1);
            context.drawTriangles(indexBuffer, 0, _drawCount * 2);
            
            context.setTextureAt(1, null);
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
            context.setVertexBufferAt(2, null);
        }
		
		public function getProgramName(mipMap:Boolean=true, repeat:Boolean=false, smoothing:String=TextureSmoothing.BILINEAR):String
        {
            // this method is called very often, so it should return quickly when called with 
            // the default parameters (no-repeat, mipmap, bilinear)
            
            var name:String = "image|";
            
            if (!mipMap) name += "N";
            if (repeat)  name += "R";
            if (smoothing != TextureSmoothing.BILINEAR) name += smoothing.charAt(0);
            
            return name;
        }
		
		/* PROPERTIES */
		
		/** 
		 * Direct access to the items vector:
		 * - ONLY FOR READING! don't add/remove items yourself
		 * - only the first <code>count</code> items are rendered
		 */
		public function getItems():Vector.<BatchItem>
		{
			return items;
		}
		
		/** Only the first <code>count</count> items are rendered */
		public function get count():int { return _drawCount; }
		
		/** Default texture */
		public function get texture():Texture { return _texture; }
		
		public function set texture(value:Texture):void 
		{
			_texture = value;
			if (!value) return;
			
			premultipliedAlpha = value.premultipliedAlpha;
			alphaVector = premultipliedAlpha 
					? new <Number>[alpha, alpha, alpha, alpha] 
					: new <Number>[1.0, 1.0, 1.0, alpha];
			
			baseVertexData = new VertexData(4);
            baseVertexData.setTexCoords(0, 0.0, 0.0);
            baseVertexData.setTexCoords(1, 1.0, 0.0);
            baseVertexData.setTexCoords(2, 0.0, 1.0);
            baseVertexData.setTexCoords(3, 1.0, 1.0);
			defaultVertexData = baseVertexData.clone();
            value.adjustVertexData(defaultVertexData, 0, 4);
		}
	}

}