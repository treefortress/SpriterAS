package starling.extensions
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	import org.osflash.signals.Signal;
	
	import starling.display.MovieClip;
	
	public class FrameClip extends Sprite
	{
		protected var frames:Object;
		protected var frameList:Vector.<Frame>;
		protected var framesByName:Object;
		
		protected var isLooping:Boolean;
		protected var _frameIndex:int;
		protected var _paused:Boolean;
		
		public var currentFrame:Frame;
		public var movieclip:MovieClip;
		public var complete:Signal;
		
		public function FrameClip(frames:Vector.<Frame>, movieclip:MovieClip) {
			super();
			this.movieclip = movieclip;
			//this.movieclip.stop();
			this.frames = frames;
			frameList = frames.concat();
			framesByName = {};
			complete = new Signal(FrameClip);
			init();
		}
		
		protected function init():void {
			//Setup a hash for quick access
			for(var i:int = 0, l:int = frameList.length; i < l; i++){
				framesByName[frameList[i].name] = frameList[i];
			}
			currentFrame = getFrameData(1);
		}
		
		public function play(value:*):void {
			
			var frame:int = value;
			if(value is String){
				frame = (framesByName[value] as Frame).startFrame;
			}
			if(frame == -1 || isNaN(frame)){ frame = 1; }
			
			_frameIndex = frame;
			movieclip.currentFrame = _frameIndex;
			movieclip.play();
			
			currentFrame = getFrameData(_frameIndex);
			
		}
		
		public function getFrameData(index:int):Frame {
			var returnFrame:Frame;
			for(var i:int = 0, l:int = frameList.length; i < l; i++){
				if(frameList[i].startFrame <= index && frameList[i].endFrame >= index){
					return frameList[i];
				}
			}
			return null;
		}
		
		public function update(elapsedTime:Number = 0):void {
			movieclip.advanceTime(elapsedTime);
			if(!movieclip.isPlaying){
				return;
			}
			if(movieclip.currentFrame == _frameIndex){
				return;
			} else {
				_frameIndex = movieclip.currentFrame
				
				if(currentFrame){
					if(movieclip.currentFrame >= currentFrame.endFrame - 1 || movieclip.currentFrame < currentFrame.startFrame - 1){
						if(!currentFrame.loop){
							movieclip.stop();
							movieclip.currentFrame = currentFrame.endFrame - 1;
							complete.dispatch(this);
						} else {
							movieclip.currentFrame = currentFrame.startFrame - 1;
						}
					} 
				}
			}
		}
		
		public function destroy():void {
		}
		
		public function stop():void {
			movieclip.stop();
		}
	}
}
