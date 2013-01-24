package treefortress.utils {
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.AsyncErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	public class URLImageLoader extends EventDispatcher {
		
		//Public properties:
		public var timeoutDuration:int = 10000;
		public var bmpImage:Bitmap;
		protected var imgLoader:Loader;
		protected var timeoutTimer:Timer;
		public var imageSrc:String;
		public var fileName:String;
		public var folderName:String;
		public var data:Object;
		
		public function URLImageLoader(){
			timeoutTimer = new Timer(timeoutDuration, 1);
			timeoutTimer.addEventListener(TimerEvent.TIMER, onTimeoutTimer, false, 0, true);
		}
		
		public function loadImage(imageSrc:String):void {
			this.imageSrc = imageSrc;
			timeoutTimer.delay = timeoutDuration;
			timeoutTimer.reset();
			timeoutTimer.start();
			
			imgLoader = new Loader();
			var names:Array = imageSrc.split("/");
			fileName = names[names.length - 1];
			if(fileName.indexOf(".") != -1){//Strip file extension
				fileName = fileName.split(".")[0];
			}
			folderName = names.length > 2? names[names.length - 2] : "";
			// Add complete listener.
			imgLoader.contentLoaderInfo.addEventListener(Event.INIT, onLoadComplete, false, 0, true);
			
			//Progress
			imgLoader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, this.dispatchEvent, false, 0, true);
			
			// Add Error Handlers:
			imgLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError, false, 0, true);
			imgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
			imgLoader.contentLoaderInfo.addEventListener(ErrorEvent.ERROR, onError, false, 0, true);
			imgLoader.contentLoaderInfo.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncError, false, 0, true);
			
			imgLoader.load(new URLRequest(imageSrc));
		}
		
		protected function onLoadComplete(event:Event):void {
			if(imgLoader == null){ return; }
			//Save image
			bmpImage = new Bitmap(event.target.content.bitmapData);
			//Remove all listeners:
			imgLoader.contentLoaderInfo.removeEventListener(Event.INIT, onLoadComplete);
			imgLoader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			imgLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			imgLoader.contentLoaderInfo.removeEventListener(ErrorEvent.ERROR, onError);
			imgLoader.contentLoaderInfo.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncError);
			
			//Clear image loader
			imgLoader.unload();
			imgLoader = null;
			
			//Notify listeners that load has completed
			timeoutTimer.stop();
			dispatchEvent(new Event(Event.COMPLETE, true));
		}
		
		protected function onProgress(event:ProgressEvent):void {
			timeoutTimer.stop();
			dispatchEvent(event);
		}
		
		protected function onError(event:ErrorEvent):void {
			trace("[ImageLoader] onError: " + event.type);
			loadFailed();
		}
		
		protected function onAsyncError(event:AsyncErrorEvent):void {
			trace("[ImageLoader] onAsyncError: " + event);
			loadFailed();
		}
		
		protected function onSecurityError(event:SecurityErrorEvent):void {
			trace("[ImageLoader] securityErrorHandler: " + event);
			loadFailed();
		}
		
		protected function onIOError(event:IOErrorEvent):void {
			trace("[ImageLoader] ioErrorHandler: " + event);
			loadFailed();
		}
		
		protected function onTimeoutTimer(event:TimerEvent):void {
			trace("[ImageLoader] Image Load Timed Out (" + imageSrc + ")");
			loadFailed();
		}
		
		protected function loadFailed():void {
			timeoutTimer.stop();
			destroy();
			if(hasEventListener(IOErrorEvent.IO_ERROR)){
				dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
			}
		}
		
		public function destroy():void {
			if(bmpImage != null && bmpImage.bitmapData) { bmpImage.bitmapData.dispose(); }
			bmpImage = null;
			
			if(imgLoader != null){
				try{ 
					imgLoader.unload();
				} catch(error:Event){}
			}
		}
	}
}