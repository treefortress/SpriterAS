package treefortress.spriter
{
	import treefortress.spriter.core.Animation;
	import treefortress.spriter.core.Child;
	import treefortress.spriter.core.ChildReference;
	import treefortress.spriter.core.Mainline;
	import treefortress.spriter.core.MainlineKey;
	import treefortress.spriter.core.Piece;
	import treefortress.spriter.core.Timeline;
	import treefortress.spriter.core.TimelineKey;
	

	public class AnimationSet
	{
		public var prefix:String;
		public var animationList:Vector.<Animation>;
		public var pieces:Vector.<Piece>;
		public var name:String;
		
		protected var piecesByFolderId:Object;
		protected var animationsByName:Object = {};
		protected var _scale:Number;
		
		public function AnimationSet(data:XML, scale:Number = 1, parentFolder:String = null){
			prefix = parentFolder || "";
			if(prefix != ""){ prefix += "/"; }
			
			_scale = scale;
			
			pieces = new <Piece>[];
			piecesByFolderId = {};
			for each(var folderXml:XML in data.folder){
				var folderId:String = folderXml.@id;
				for each(var file:XML in folderXml.file){
					var piece:Piece = new Piece();
					piece.id = file.@id;
					piece.folder = folderId;
					piece.name = file.@name;
					piece.name = piece.name.split(".")[0];
					//Strip preceding classes (Spriter is injecting them for no reason. Bug?)
					if(piece.name.substr(0, 1) == "/"){
						piece.name = piece.name.substr(1);
					}
					piece.width = file.@width * _scale;
					piece.height = file.@height * _scale;
					piece.pivotX = (file.@pivot_x == undefined)? 0 : file.@pivot_x;
					piece.pivotY = (file.@pivot_y == undefined)? 1 : file.@pivot_y;
					piecesByFolderId[piece.folderId] = piece;
				}
			}
			
			animationList = new Vector.<Animation>;
			var anim:Animation;
			
			var mainlineKeys:Vector.<MainlineKey>;
			var mainlineKey:MainlineKey;
			
			var timelineKeys:Vector.<TimelineKey>;
			var timelineKey:TimelineKey;
			
			for each(var animData:XML in data.entity.animation) {
				anim = new Animation();
				anim.id = animData.@id;
				anim.name = animData.@name;
				anim.length = animData.@length;
				anim.looping = (animData.@looping == undefined || animData.@looping == true);
				
				//Add timelines
				for each(var timelineData:XML in animData.timeline) {
					timelineKeys = new <TimelineKey>[];
					anim.timelineList.push(new Timeline(timelineData.@id, timelineKeys));
					
					//Add TimelineKeys
					for each(var keyData:XML in timelineData.key) {
						timelineKey = new TimelineKey();
						timelineKey.id = keyData.@id;
						timelineKey.time = keyData.@time;
						timelineKey.spin = keyData.@spin;
						
						//Check whether it's a bone (Assume: if not an object, it must be a bone)
						var isBone:Boolean = false;
						var childData:XML = keyData..object[0];
						if(!childData){ 
							childData = keyData..bone[0];
							isBone = true;
						}
						if(!childData || childData.@file == undefined){ continue; }
						
						var child:Child = new Child();
						child.x = childData.@x * scale;
						child.y = childData.@y * scale;
						child.angle = childData.@angle;
						child.alpha = (childData.@a == undefined)? 1 : childData.@a;
						
						//Convert to flash degrees (spriters uses 0-360, flash used 0-180 and -180 to -1)
						var rotation:Number = child.angle;
						if(rotation >= 180){ rotation = 360 - rotation;
						} else { rotation = -rotation; }
						child.angle = rotation;
						
						//Ignore bones
						if(!isBone){
							child.piece = piecesByFolderId[childData.@folder + "_" + childData.@file];
							child.pivotX = (childData.@pivot_x == undefined)? child.piece.pivotX : childData.@pivot_x;
							child.pivotY = (childData.@pivot_y == undefined)? child.piece.pivotY : childData.@pivot_y;
							child.pixelPivotX = child.piece.width * child.pivotX;
							child.pixelPivotY = child.piece.height * (1 - child.pivotY);
						}
						child.scaleX = (childData.@scale_x == undefined)? 1 : childData.@scale_x;
						child.scaleY = (childData.@scale_y == undefined)? 1 : childData.@scale_y;
						
						timelineKey.child = child;
						timelineKeys.push(timelineKey);
					}
				}
				
				//Add Mainline
				mainlineKeys = new <MainlineKey>[];
				for each(var mainKey:XML in animData.mainline.key) {
					
					//Add Main Keyframes
					mainlineKey = new MainlineKey();
					mainlineKey.id = mainKey.@id;
					mainlineKey.time = mainKey.@time;
					mainlineKeys.push(mainlineKey);
					
					//Add Object to KeyFrame
					mainlineKey.refs = new <ChildReference>[];
					for each(var refData:XML in mainKey.object_ref) {
						var ref:ChildReference = new ChildReference();
						ref.id = refData.@id;
						ref.timeline = refData.@timeline; //timelineId
						ref.key = refData.@key; //timelineKey
						ref.zIndex = refData.@z_index;
						mainlineKey.refs.push(ref);
					}
				}
				
				//A bit of a hack to support Animation Looping...
				if(anim.looping && anim.length > mainlineKey.time){
					//Automatically insert a new MainLineKey at the very end of the animation, 
					var endKey:MainlineKey = new MainlineKey();
					endKey.time = anim.length;
					endKey.id = mainlineKey.id + 1;
					//Use the references from the first frame to create the looping effect
					endKey.refs = mainlineKeys[0].refs;
					mainlineKeys.push(endKey);
				}
				
				anim.mainline = new Mainline(mainlineKeys);
				animationsByName[anim.name] = anim;
				animationList.push(anim);
			}
		}
		
		public function get scale():Number {
			return _scale;
		}

		public function getByName(name:String):Animation {
			return animationsByName[name];
		}
	}
}
