package as;

enum TextAlign {
	@serialize("l") A_Left;
	@serialize("r") A_Right;
	@serialize("c") A_Center;
}

class Text extends Asset {
	public static var ALL : Array<Text> = [];
	static var EMPTY = "???";
	static var SIZES = [13,22,30];
	
	var tf			: flash.text.TextField;
	var txt			: String;
	var fontSize	: Int;
	public var align(default,null)	: TextAlign;
	
	public function new(?str="") {
		super();
		ALL.push(this);
		fontSize = SIZES[1];
		align = A_Center;
		
		tf = man.createField("Room", fontSize);
		sprite.addChild(tf);
		tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
		tf.height = 30;
		tf.y = -4;
		setText(str);
		
		man.dm.add(sprite, Const.DP_TEXT);
	}
	
	override function serialize() {
		var d = super.serialize();
		var meta = haxe.rtti.Meta.getFields(TextAlign);
		d.data = {
			txt : txt,
			align : Reflect.field(meta, Std.string(align)).serialize[0],
			s : getSize(),
		}
		return d;
	}
	
	override function applySerializedData(adata) {
		super.applySerializedData(adata);
		setText(adata.txt);
		
		var meta = haxe.rtti.Meta.getFields(TextAlign);
		var a = A_Center;
		for(k in Type.getEnumConstructs(TextAlign)) {
			if( Reflect.field(meta, k).serialize[0]==adata.align )
				a = Type.createEnum(TextAlign, k);
		}
		setAlign(a);
		
		setSize(adata.s);
	}
	
	public function setAlign(a:TextAlign) {
		align = a;
		redraw();
	}
	
	override function isOver(x,y) {
		//if( man.tool!=Const.Tool.TText )
			//return false;
			
		var w = Math.ceil(tf.textWidth/Const.GRID);
		switch( align ) {
			case A_Center :
				return x>=cx-w*0.5 && x<=cx+w*0.5 && y==cy;
				
			case A_Left :
				return x>=cx && x<cx+w && y==cy;
				
			case A_Right :
				return x>=cx-w+1 && x<=cx && y==cy;
		}
	}
	
	public function getText() {
		return txt==EMPTY ? "" : txt;
	}
	
	public function getSize() {
		var i = 0;
		for(s in SIZES) {
			if( fontSize==s )
				return i;
			i++;
		}
		return 0;
	}
	
	public function setSize(s) {
		if( s<0 )
			s = 0;
			
		if( s>=SIZES.length )
			s = SIZES.length-1;
			
		fontSize = SIZES[s];
		redraw();
	}
	
	public function setText(str:String) {
		txt = StringTools.trim(str);
		if( txt.length==0 )
			txt = EMPTY;
		redraw();
	}
	
	override function redraw() {
		super.redraw();
		
		sprite.graphics.clear();
		
		var f = tf.getTextFormat();
		f.color = Const.THEME.wall;
		f.size = fontSize;
		tf.setTextFormat(f);
		tf.defaultTextFormat = f;
		
		tf.text = txt;
		switch( align ) {
			case A_Center :
				tf.x = Std.int(Const.GRID*0.5 - tf.textWidth*0.5 - 4);
				
			case A_Left :
				tf.x = 0;
				
			case A_Right :
				tf.x = Std.int(Const.GRID - tf.textWidth);
		}
		tf.y = Std.int(Const.GRID*0.5 - tf.textHeight*0.5 - 2);
		
		sprite.filters = [
			new flash.filters.GlowFilter(Const.THEME.bg, 1, 8,8,2),
		];
	}
	
	override public function destroy() {
		super.destroy();
		ALL.remove(this);
	}
}

