package treefortress.spriter.core
{
	public class Animation
	{
		public var name:String;
		public var id:int;
		public var length:int;
		public var position:int;
		public var looping:Boolean;
		
		public var timelineList:Vector.<Timeline>;
		public var mainline:Mainline;
	
		public function Animation() {
			timelineList = new <Timeline>[];
		}
	}
}