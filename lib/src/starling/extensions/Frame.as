package starling.extensions
{
	public class Frame
	{
		public var startFrame:int;
		public var endFrame:int;
		public var loop:Boolean;
		public var name:String;
		
		public function Frame(name:String, startFrame:int, endFrame:int, loop:Boolean = false) {
			this.name = name;
			this.startFrame = startFrame;
			this.endFrame = endFrame;
			this.loop = loop;
		}
	}
}