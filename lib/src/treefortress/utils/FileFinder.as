package treefortress.utils {
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FileListEvent;
	import flash.filesystem.File;
	import flash.utils.getTimer;
	
	public class FileFinder extends EventDispatcher {
		
		
		/**
		 * The filePath of every file found. 
		 */
		protected var _fileList:Array;
		public function get fileList():Array{
			return _fileList;
		}
		
		/**
		* Array of valid fileTypes to be returned;
		*/
		public var fileTypes:Array = ["png", "jpeg", "gif", "bmp", "jpg"];
		
		protected var directoryList:Array = [];
		protected var currentFolder:File;
		protected var startTime:int;
		protected var dirCount:int = 0;
		protected var rootCount:int = 0;
		
		public function FileFinder():void {
		}
		
		public function run(directoryList:Array = null):void {
			
			if(directoryList != null){ 
				_fileList = [];
				this.directoryList = directoryList.concat(); 
				directoryList = this.directoryList;
				//Trim child directories, keep only the roots:
				var indexOf:int;
				var matchCount:int;
				dirCount = directoryList.length;
				directoryList.sort();
				for(var i:int = 0; i < directoryList.length; i++){
					for(var j:int = directoryList.length - 1; j >= 0; j--){
						if(directoryList[j].indexOf(directoryList[i]) != -1 && j != i){ 
							directoryList.splice(j, 1);
						}
					}
				}
				dirCount = directoryList.length;
				rootCount = directoryList.length;
				startTime = getTimer()
				trace("[FileFinder] Begin directory search...", directoryList[0]);
			}
			if(this.directoryList.length == 0){
				trace("[FileFinder] Search Complete -- Directories Searched: ", dirCount, ", Files Found:", fileList.length, ", Elapsed Time: ", (getTimer() - startTime)/1000, "seconds");
				dispatchEvent(new Event(Event.COMPLETE));
				return;
			}
			
			var file:File = new File(this.directoryList.shift());
			getFileListing(file.url);
		}
		
		protected function getFileListing(folder:String):void {
			//the current folder object	
			currentFolder = new File(folder);
			
			//Skip hidden files / directories
			if(currentFolder.isHidden && currentFolder.parent != null){ 
				run(); 
				return;
			}
			//the current folder's file listing
			currentFolder.getDirectoryListingAsync();
			currentFolder.addEventListener(FileListEvent.DIRECTORY_LISTING, onDirectoryListing);
			
		}
		
		protected function onDirectoryListing(event:FileListEvent):void {
			var files:Array = event.files;
			var l:int = files.length;
			//iterate and put files in the result and process the sub folders recursively
			for (var i:int = 0; i < l; i++) {
				var file:File = files[i] as File;
				if (file.isDirectory) {
					if (file.name !="." && file.name !="..") {
						//it's a directory
						directoryList.push(files[i].url);
						dirCount++;
						trace(files[i].url);
					}
				} else {
					//it's a file
					if(file.extension && fileTypes.indexOf(file.extension.toLowerCase()) != -1){
						fileList.push(file.url);
					}
				}
			}
			currentFolder.removeEventListener(FileListEvent.DIRECTORY_LISTING, onDirectoryListing);
			run();
		}
		
		public function destroy():void {
			_fileList = null;
			directoryList = null;
			currentFolder = null;
		}
		
	}
}