package treefortress.spriter
{
	
	import flash.utils.getTimer;
	
	import org.osflash.signals.Signal;
	
	import starling.animation.IAnimatable;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import treefortress.spriter.core.Animation;
	import treefortress.spriter.core.Child;
	import treefortress.spriter.core.MainlineKey;
	import treefortress.spriter.core.Timeline;
	import treefortress.spriter.core.TimelineKey;
	
	public class SpriterClip extends Sprite implements IAnimatable
	{
		protected static var TO_RADS:Number = Math.PI/180;
		
		//Protected
		protected var textureAtlas:TextureAtlas;
		protected var animations:AnimationSet;
		protected var container:Sprite;
		
		protected var frameIndex:int = 0;
		protected var frame:MainlineKey;
		protected var nextFrame:MainlineKey;
		
		protected var callbackList:Array;
		protected var swapHash:Object;
		protected var imagesByTimeline:Object;
		protected var imagesByName:Object;
		protected var texturesByName:Object;
		
		protected var _isPlaying:Boolean;
		
		/** Public **/
		public var animation:Animation;
		public var animationComplete:Signal;
		public var playbackSpeed:Number = 1;
		public var position:Number;	
		public var animationWidth:Number;
		public var animationHeight:Number;
		public var animationFactor:Number = 1;
		public var ignoredPieces:Object;
		
		/** HELPERS VARS, declared at the class level to avoid any instanciation in the main update loop. */
		protected var lastTime:int;
		protected var updateFrame:Boolean;
		protected var timelineId:int;
		protected var textures:Vector.<Texture>;
		protected var firstRun:Boolean;
		protected var pieceName:String;
		protected var minX:int;
		protected var minY:int; 
		protected var r:Number;
		protected var child:Child;
		protected var nextChild:Child;
		protected var image:Image; 
		protected var i:int; 
		protected var l:int;
		protected var startTime:int;
		protected var endTime:int;
		protected var lerpAmount:Number;
		protected var timeline:Timeline;
		protected var key:TimelineKey;
		protected var spinDir:int;
		protected var angle1:Number;
		protected var angle2:Number;
		protected var rangeValue:Number;
		/* END HELPER VARS */
		
		public function SpriterClip(animations:AnimationSet, textureAtlas:TextureAtlas){
			this.textureAtlas = textureAtlas;
			this.animations = animations;
			callbackList = [];
			swapHash = {};
			imagesByTimeline = {};
			texturesByName = {};
			imagesByName = {};
			ignoredPieces = {};
			
			container = new Sprite();
			addChild(container);
			
			animationComplete = new Signal();
			this.touchable = false;
		}
		
		override public function set touchable(value:Boolean):void {
			super.touchable = value;
			container.touchable = value;
		}
		
		public function addCallback(callback:Function, time:int, addOnce:Boolean = true):void {
			callbackList.push({call: callback, time: time, addOnce: addOnce});
		}
			
			
		public function get isPlaying():Boolean { return _isPlaying; }
		
		public function play(name:String, startPosition:int = 0, clearCallbacks:Boolean = false):void {
			if(!animations.getByName(name)){
				//throw(new Error("[SpriterSprite] Unable to find animation name: " + name));
				return;
			}
			animation = animations.getByName(name);
			position = startPosition;
			
			if(clearCallbacks){
				callbackList.length = 0;
			}
			
			_isPlaying = true;
			frameIndex = -1;
			frame = nextFrame = animation.mainline.keys[0];
			if(animation.mainline.keys.length > 1){
				nextFrame = animation.mainline.keys[1];
			} 
			lastTime = getTimer();
			update(0, true);
			
		}
		
		public function advanceTime(time:Number):void {
			update(time * 1000);
		}
		
		
		public function update(elapsed:int = 0, forceNextFrame:Boolean = false):void {
			if(!_isPlaying){ return; }; // Exit if we're not currently playing
			//if(elapsed > 50){ elapsed = 50; }
			
			position += elapsed * playbackSpeed;
			updateCallbacks();
			
			updateFrame = true;
			
			minX = minY = int.MAX_VALUE;
			startTime = frame.time;
			endTime = nextFrame? nextFrame.time : 0;
			
			if(endTime == 0){ endTime = animation.length; }
			
			lastTime = getTimer();
			//Large, total frame update (updates z-depth)
			if((position == 0) || forceNextFrame || position > endTime || position > animation.length){
				
				//updateFrame = false;
				
				//Advance playhead
				if(frameIndex < animation.mainline.keys.length - 2){
					if(frameIndex == -1){ frameIndex = 0; }
					while(animation.mainline.keys[frameIndex].time < position){
						frameIndex++;
						if(frameIndex >= animation.mainline.keys.length - 2){
							frameIndex = animation.mainline.keys.length - 2;
							break; 
						}
					}
					if(animation.mainline.keys[frameIndex].time > position){
						frameIndex--;
						//updateFrame = true;
					}
				} else { frameIndex = 0; }
				
				//Animation complete?
				if(position > animation.length){ 
					position = 0; 
					animationComplete.dispatch();
					
					for(i = callbackList.length - 1; i >= 0; i--){
						callbackList[i].called = false;
					}
					
					if(animation.looping == false){
						_isPlaying = false;
						return;//Exit Animation!
					} else {
						frameIndex = 0;
					}
				}
				
				if(frameIndex > 0 || animation.looping){
					frame = animation.mainline.keys[frameIndex];
					if(animation.mainline.keys.length > frameIndex + 1){
						nextFrame = animation.mainline.keys[frameIndex + 1];
					}
					startTime = frame.time;
					endTime = nextFrame? nextFrame.time : 0;
					if(endTime == 0){ endTime = animation.length; }
				}
				
				firstRun = container.numChildren == 0;
				container.removeChildren();
				
				for(i = 0, l = frame.refs.length; i < l; i++){
					timelineId = frame.refs[i].timeline;
					child = animation.timelineList[timelineId].keys[frame.refs[i].key].child;
					if(!child.piece){ continue; }
					
					image = imagesByTimeline[timelineId];
					if(!image){
						image = createImageByName(child.piece.name);
						imagesByTimeline[timelineId] = image;
					}
					container.addChild(image);
					
					//If this piece is set to be ignored, do not update any of it's position data
					if(ignoredPieces[image.name]){ continue; }
					
					image.pivotX = child.pixelPivotX;
					image.pivotY = child.pixelPivotY;
					
					image.x = child.x;
					if(image.x < minX){ minX = image.x; }
					
					image.y = -child.y;
					if(image.y < minY){ minY = image.y; }
					
					image.scaleX = child.scaleX;
					image.scaleY = child.scaleY;
					
					image.rotation = child.angle * TO_RADS;
				}
				//Measure this animation
				if(isNaN(animationWidth) && isNaN(animationWidth) && frameIndex == 0){
					animationWidth = Math.abs(minX * 2) + container.width;
					animationHeight =  Math.abs(minY * 2) + container.height;
				}
				
			}
			//Incremental interpolated update
 			if(updateFrame) {
				
				lerpAmount = (position - startTime)/(endTime - startTime);
				//trace(amount);
				spinDir = 0;
				
				for(i = 0, l = frame.refs.length; i < l; i++){
					timeline = animation.timelineList[frame.refs[i].timeline];
					key = timeline.keys[frame.refs[i].key];
					child = key.child;
					nextChild = timeline.keys[frame.refs[i].key + 1].child;
					
					image = imagesByTimeline[timeline.id];
					if(!image){
						image = createImageByName(child.piece.name);
						imagesByTimeline[timelineId] = image;
					}
					
					//If this piece is set to be ignored, do not update any of it's position data
					if(ignoredPieces[image.name]){ continue; }
					
					if(child.pixelPivotX != nextChild.pixelPivotX){
						image.pivotX = lerp(child.pixelPivotX, nextChild.pixelPivotX, lerpAmount);
					}
					if(child.pixelPivotY != nextChild.pixelPivotY){
						image.pivotY = lerp(child.pixelPivotY, nextChild.pixelPivotY, lerpAmount);
					}
					if(child.x != nextChild.x){
						image.x = lerp(child.x, nextChild.x, lerpAmount);
					}
					if(child.y != nextChild.y){
						image.y = lerp(-child.y, -nextChild.y, lerpAmount);
					}
					if(child.scaleX != nextChild.scaleX){
						image.scaleX = lerp(child.scaleX, nextChild.scaleX, lerpAmount);
					}
					if(child.scaleY != nextChild.scaleY){
						image.scaleY = lerp(child.scaleY, nextChild.scaleY, lerpAmount);
					}
					if(child.angle != nextChild.angle){
						
						//Rotate to closest direction (ignore 'dir' for now, it's unsupported in the current Spriter A4 build)
						angle1 = child.angle;
						angle2 = nextChild.angle;
						
						rangeValue = angle2 - angle1;
						
						if (rangeValue > 180) { rangeValue -= 360; }
						else if (rangeValue < -180) { rangeValue += 360; }
						
						r = angle1 + rangeValue * lerpAmount;						
						image.rotation = r * TO_RADS;
					}
				}
			}
		}
		
		protected function updateCallbacks():void {
			for(var i:int = callbackList.length - 1; i >= 0; i--){
				if(callbackList[i].time <= position && callbackList[i].called != true){
					callbackList[i].call();
					if(callbackList[i].addOnce){
						callbackList.splice(i, 1);
					} else {
						callbackList[i].called = true;
					}
				}
			}
		}
		
		[Inline]
		final protected function lerp(val1:Number, val2:Number, amount:Number):Number {
			return val1 + (val2 - val1) * amount;
		}
		
		protected function createImageByName(name:String):Image {
//			/name = name;
			//Check if there's an existing swap for this image
			var swapName:String = name;
			if(swapHash[name]){ swapName = swapHash[name]; }
			
			var texture:Texture = getTexture(swapName);
			//If we couldn't retrieve a swap, use the original as a fallback
			if(!texture){ texture = getTexture(name); } 
			//If we still can't find a texture, this is an invalid piece name;
			if(!texture){
				throw(new Error("[SpriterSprite] ERROR: Unable to find a texture for piece named: " + name + ". Make sure you've passed the correct folder prefix to your Animation Set (if you're using one)"));
			}
			
			var image:Image = new Image(texture);
			image.name = name;
			imagesByName[name] = image;
			return image;
		}
		
		public function getTexture(name:String):Texture {
			if(animations.prefix && name.indexOf(animations.prefix) == -1){
				name = animations.prefix + name;
			}
			if(!texturesByName[name]){
				var textures:Vector.<Texture> = textureAtlas.getTextures(name);
				if(textures.length == 0){ return null; }
				texturesByName[name] = textures[0];
			}
			return texturesByName[name];
		}
		
		public function getImage(name:String):Image {
			return imagesByName[name];
		}
		
		public function excludePiece(piece:*, ignore:Boolean):void {
			if(piece is String){
				ignoredPieces[piece] = ignore;
			} else if(piece is Image) {
				ignoredPieces[piece.name] = ignore;
			}
		}
		
		public function swapPiece(piece:String, newPiece:String):void {
			if(animations.prefix && piece.indexOf(animations.prefix) == -1){
				piece = animations.prefix + piece;
			}
			//var oldTex:Texture = texturesByName[piece];
			//if(!oldTex){ return; } //Can't swap if we can't find this textures
			
			var newTex:Texture = getTexture(newPiece);
			if(!newTex){ return; } //Can't swap if we can't find this textures
			
			var image:Image;
			for(var o:Object in imagesByTimeline){
				image = imagesByTimeline[o] as Image;
				if(image.name == piece){
					image.texture = newTex;
				}
			}
		}
		
		public function swapAll(segment1:String, segment2:String):void {
			var name:String;
			for(var i:int = 0, l:int = animations.pieces.length; i < l; i++){
				name = animations.pieces[i].name;
				if(name.indexOf(segment1) != -1){
					var swap:String = name.replace(segment1, segment2);
					swapPiece(name, swap);
				}
			}
		}
		public function unswapPiece(piece:String):void {
			if(animations.prefix && piece.indexOf(animations.prefix) == -1){
				piece = animations.prefix + piece;
			}
			var image:Image;
			for(var o:Object in imagesByTimeline){
				image = imagesByTimeline[o] as Image;
				if(image.name == piece){
					image.texture = getTexture(piece);
				}
			}
		}
		
		public function unswapAll():void {
			var image:Image;
			for(var o:Object in imagesByTimeline){
				image = imagesByTimeline[o] as Image;
				image.texture = getTexture(animation.timelineList[o].keys[0].child.piece.name);
			}
		}
		
		public function stop():void {
			_isPlaying = false;
			
		}
	}
}