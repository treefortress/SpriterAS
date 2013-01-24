package treefortress.spriter.core
{
	public class Timeline
	{
		public var id:String;
		public var keys:Vector.<TimelineKey>
		
		public function Timeline(id:String, keys:Vector.<TimelineKey>){
			this.id = id;
			this.keys = keys;
		}
	}
}