package treefortress.spriter.core
{
	public class Piece
	{
		public var id:String;
		public var folder:String;
		public var name:String;
		public var width:int;
		public var height:int;
		
		public function Piece() {
		}
		
		public function get folderId():String {
			return folder + "_" + id;
		}
		
		
	}
}