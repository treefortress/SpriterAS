package treefortress.spriter
{
	
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import org.osflash.signals.Signal;
	
	import starling.animation.IAnimatable;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import starling.textures.TextureSmoothing;
	
	import treefortress.spriter.core.Animation;
	import treefortress.spriter.core.Child;
	import treefortress.spriter.core.MainlineKey;
	import treefortress.spriter.core.Timeline;
	import treefortress.spriter.core.TimelineKey;
	
	public class SpriterClip extends Sprite implements IAnimatable
	{
		protected static var TO_RADS:Number = Math.PI/180;
		
		// Protected
		public var container:Sprite;
		
		protected var frameIndex:int = 0;
		protected var frame:MainlineKey;
		protected var nextFrame:MainlineKey;
		
		protected var callbackList:Vector.<Callback>;
		protected var swapHash:Object;
		protected var imagesByTimeline:Object;
		protected var imagesByName:Object;
		protected var texturesByName:Object;
		protected var texturesByImage:Dictionary;
		protected var childImages:Vector.<Image>;
		
		protected var _isPlaying:Boolean;
		protected var currentColor:Number;
		
		
		// Public
		public var textureAtlas:TextureAtlas;
		public var animations:AnimationSet;
		public var animation:Animation;
		public var animationComplete:Signal;
		public var playbackSpeed:Number = 1;
		public var position:Number;	
		public var animationWidth:Number;
		public var animationHeight:Number;
		public var animationFactor:Number = 1;
		public var ignoredPieces:Object;
		
		// tmp vars, to avoid memory allocation in the main loop. */
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
		protected var nameHash:String;
		protected var tmpNameHash:String;
		protected var clearChildren:Boolean;
		protected var advanceFrame:Boolean;
		// end tmp vars		
		
		public function SpriterClip(animations:AnimationSet, textureAtlas:TextureAtlas){
			this.textureAtlas = textureAtlas;
			this.animations = animations;
			callbackList = new <Callback>[];
			swapHash = {};
			imagesByTimeline = {};
			texturesByName = {};
			imagesByName = {};
			ignoredPieces = {};
			texturesByImage = new Dictionary(true);
			childImages = new <Image>[];
			
			container = new Sprite();
			addChild(container);
			
			animationComplete = new Signal(SpriterClip);
			this.touchable = false;
		}
		
		override public function set touchable(value:Boolean):void {
			super.touchable = value;
			container.touchable = value;
		}
		
		public function addCallback(callback:Function, time:int, addOnce:Boolean = true):void {
			if(time > animation.length){ time = animation.length; }
			callbackList.push(new Callback(callback, Math.min(time, animation.length), addOnce));
		}
		
		public function get isPlaying():Boolean { return _isPlaying; }
		
		public function setPosition(x:int, y:int):void {
			this.x = x;
			this.y = y;
		}
		
		public function play(name:String, startPosition:int = 0, clearCallbacks:Boolean = false):void {
			if(!animations.getByName(name)){
				//throw(new Error("[SpriterSprite] Unable to find animation name: " + name));
				return;
			}
			animation = animations.getByName(name);
			position = startPosition;
			
			//Empty the callback list
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
		
		public function stop():void {
			_isPlaying = false;	
		}
		
		public function clearCallbacks():void {
			callbackList.length = 0;
		}
		
		/** Hook for Starling Juggler Interface **/
		public function advanceTime(time:Number):void {
			update(time * 1000);
		}
		
		public function update(elapsed:int = 0, forceNextFrame:Boolean = false):void {
			if(!_isPlaying){ return; }; // Exit if we're not currently playing
			
			position += elapsed * playbackSpeed;
			updateCallbacks();
			
			minX = minY = int.MAX_VALUE;
			startTime = frame.time;
			endTime = nextFrame? nextFrame.time : 0;
			
			if(endTime == 0 || endTime > animation.length){ endTime = animation.length; }
			lastTime = getTimer();
			
			//Determine whether we need to advance a frame
			advanceFrame = false;
			//Clip is just starting...
			if(position == 0 || frameIndex == -1){ advanceFrame = true; }
			//Key frame has been passed
			if(position > endTime){ 
				advanceFrame = true; 
				//Reached the end of the timeline, don't advance keyFrame
				if(frameIndex == animation.mainline.keys.length - 2){
					advanceFrame = false;
				}
			}
			//Animation has completed, or Explicit override 
			if(position > animation.length || forceNextFrame){ 
				advanceFrame = true; 
			}
			if(advanceFrame){
				//Advance playhead
				if(frameIndex < animation.mainline.keys.length - 2){
					if(frameIndex == -1){ frameIndex = 0; }
					while(animation.mainline.keys[frameIndex].time < position){
						frameIndex++;
						if(frameIndex > animation.mainline.keys.length - 2){
							frameIndex = animation.mainline.keys.length - 2;
							break; 
						}
					}
					if(animation.mainline.keys[frameIndex].time > position){
						frameIndex--;
					}
				} else { frameIndex = 0; }
				
				//trace("ADVANCE FRAME: " + position);
				//Animation complete?
				if(position > animation.length){ 
					position = 0; 
					
					//Reset all callbacks, TODO: Check if any callbacks on this final frame?
					for(i = callbackList.length - 1; i >= 0; i--){
						callbackList[i].called = false;
					}
					
					//Loop or stop pakying...
					if(animation.looping){
						frameIndex = 0;
					} else {
						_isPlaying = false;
					}
					animationComplete.dispatch(this);
					if(!_isPlaying){ return; }	
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
				//Optimization, check whether we need to remove any children?
				optimizedRemoveChildren();
				childImages.length = 0;
				
				for(i = 0, l = frame.refs.length; i < l; i++){
					timelineId = frame.refs[i].timeline;
					if(animation.timelineList[timelineId].keys.length == 0){ continue; }
					child = animation.timelineList[timelineId].keys[frame.refs[i].key].child;
					if(!child.piece){ continue; }
					
					//Create one image/timeline, and cache it off.
					image = imagesByTimeline[timelineId];
					if(!image){
						image = createImageByName(child.piece.name);
						imagesByTimeline[timelineId] = image;
					}
					childImages.push(image);
					
					//Add the child to displayList if it isn't already
					if(!image.parent){
						container.addChild(image);
					}
					//Make sure the image has the textures it's supposed to (one timeline can have multiple images). 
					if(texturesByImage[image] != getTexture(child.piece.name)){
						texturesByImage[image] = getTexture(child.piece.name);
						image.texture = texturesByImage[image];
					}
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
					image.rotation = fixRotation(child.angle) * TO_RADS;
				}
				//Measure this animation
				if(isNaN(animationWidth) && isNaN(animationWidth) && frameIndex == 0){
					animationWidth = Math.abs(minX * 2) + container.width;
					animationHeight =  Math.abs(minY * 2) + container.height;
				}
			}
			
			//Small, Incremental interpolated update
			if(position < endTime){
				
				spinDir = 0;
				
				for(i = 0, l = frame.refs.length; i < l; i++){
					
					//Get the most recent previous timeline for reference
					timeline = animation.timelineList[frame.refs[i].timeline];
					if(!timeline.keys.length){ continue; }
					
					var lerpStart:Number = startTime;
					var lerpEnd:Number = endTime;
					child = null;
					nextChild = null;
					key = timeline.keys[0];
					
					//Find the previous and next key's for this particular timeline.
					for(var i2:int = 0, l2:int = timeline.keys.length; i2 < l2; i2++){
						//Looks for end frame
						if(timeline.keys[i2].time > position){
							if(!nextChild){
								nextChild = timeline.keys[i2].child;
								lerpEnd = timeline.keys[i2].time;
							} else { break; }
						} 
						//Look for start frame
						if(timeline.keys[i2].time <= position){
							child = timeline.keys[i2].child;
							lerpStart = timeline.keys[i2].time;
						}
					}
					//If we couldn't find a next frame, this animation file is probably missing an endFrame. Substitute startFrame.
					if(!nextChild){ 
						nextChild = timeline.keys[0].child; 
						lerpEnd = animation.length;
					}
					
					//Determine interpolation amount
					lerpAmount = (position - lerpStart)/(lerpEnd - lerpStart);
					
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
					if(child.alpha != nextChild.alpha){
						image.alpha = lerp(child.alpha, nextChild.alpha, lerpAmount);
					}
					
					if(child.angle != nextChild.angle){
						
						//Rotate to closest direction (ignore 'dir' for now, it's unsupported in the current Spriter A4 build)
						angle1 = child.angle;
						angle2 = nextChild.angle;
						rangeValue = angle2 - angle1;
						rangeValue = fixRotation(rangeValue);
						
						r = angle1 + rangeValue * lerpAmount;						
						image.rotation = r * TO_RADS;
					}
				}
			}
		}
		
		protected function fixRotation(rotation:Number):Number {
			if (rotation > 180) { rotation -= 360; }
			else if (rotation < -180) { rotation += 360; }
			return rotation;
		}
		
		[Inline]
		final protected function optimizedRemoveChildren():void {
			clearChildren = true;
			if(childImages.length > 0){
				tmpNameHash = "";
				for(i = 0, l = childImages.length; i < l; i++){
					tmpNameHash += childImages[i].name + "|";
				}
				if(tmpNameHash == nameHash && nameHash != ""){
					clearChildren = false;
				}
				nameHash = tmpNameHash
			}
			if(clearChildren){ 
				//trace("Remove Children");
				container.removeChildren(); 
			} 
		}
		
		[Inline]
		final protected function updateCallbacks():void {
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
			
			//Check if there's an existing swap for this image
			var swapName:String = name;
			if(swapHash[name]){ swapName = swapHash[name]; }
			//trace("[CreateImage] " + name);
			
			var texture:Texture = getTexture(swapName);
			//If we couldn't retrieve a swap, use the original as a fallback
			if(!texture){ texture = getTexture(name); } 
			//If we still can't find a texture, this is an invalid piece name;
			if(!texture){
				throw(new Error("[SpriterSprite] ERROR: Unable to find a texture for piece named: " + name + ". Make sure you've passed the correct folder prefix to your Animation Set (if you're using one)"));
			}
			
			var image:Image = new Image(texture);
			//image.smoothing = TextureSmoothing.NONE;
			image.name = name;
			if(!isNaN(currentColor)){
				image.color = currentColor;
			}
			imagesByName[name] = image;
			
			return image;
		}
		
		public function setColor(value:Number):void {
			for(var name:String in imagesByName){
				imagesByName[name].color = value;
			}
			currentColor = value;
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
		
		public function excludePiece(piece:*, ignore:Boolean = true):void {
			if(piece is String){
				ignoredPieces[piece] = ignore;
			} else if(piece is Image) {
				ignoredPieces[piece.name] = ignore;
			}
		}
		
		public function includePiece(piece:*):void {
			excludePiece(piece, false);
		}
		
		public function swapPiece(piece:String, newPiece:String):void {
			if(animations.prefix && piece.indexOf(animations.prefix) == -1){
				piece = animations.prefix + piece;
			}
			
			var newTex:Texture = getTexture(newPiece);
			if(!newTex){ newTex = getTexture(newPiece); } //Check for preceding forward slash, newer versions of Spriter seem to add this.
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
	}
}

class Callback {
	
	public var call:Function;
	public var time:int;
	public var addOnce:Boolean;
	public var called:Boolean;
	
	public function Callback(call:Function, time:int, addOnce:Boolean = false):void {
		this.call = call;
		this.time = time;
		this.addOnce = addOnce;
	}
	
}