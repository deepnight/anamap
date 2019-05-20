import mt.deepnight.SpriteLibBitmap;
import flash.display.Sprite;

import Const;

class Asset {
	public static var ALL : Array<Asset> = new Array();
	public static var HIGHLIGHTED : Null<Asset> = null;
	
	public var man			: Manager;
	public var type			: AssetType;
	
	public var cx			: Int;
	public var cy			: Int;
	public var sprite		: BSprite;
	public var dir			: Int;
	
	public var draftMode(default, set)	: Bool;
	
	public var useErrorRender: Bool;
	
	public function new() {
		man = Manager.ME;
		ALL.push(this);
		useErrorRender = false;
		
		cx = cy = 0;
		dir = 0;
		draftMode = man.level.draftMode;
		
		sprite = new BSprite();
		man.dm.add(sprite, Const.DP_ASSET);
		sprite.mouseChildren = sprite.mouseEnabled = false;
		
		sprite.filters = [
			new flash.filters.DropShadowFilter(3,45, 0x0,0.3, 4,4),
		];
	}
	
	public function setAsCursor() {
		ALL.remove(this);
	}
	
	public function onThemeChange() {
		redraw();
	}
	
	public function set_draftMode(b) {
		draftMode = b;
		return b;
	}
	
	public function isOver(x,y) {
		return cx==x && cy==y;
	}
	
	public function redraw() {
		if( useErrorRender ) {
			sprite.graphics.clear();
			sprite.graphics.beginFill(0xFF0000,1);
			sprite.graphics.drawRect(0,0, Const.GRID, Const.GRID);
		}
	}
	
	public function rotate() {
		dir++;
		if( dir>3 )
			dir = 0;
	}
	
	function getRandom() : mt.Rand {
		return new mt.Rand(cx+cy*man.level.wid);
	}
	
	public function setPos(x,y) {
		cx = x;
		cy = y;
		redraw();
	}
	
	public function serialize() {
		return {
			t		: type,
			x		: cx,
			y		: cy,
			d		: dir,
			data	: null,
		}
	}
	
	public static function fromJson(adata : Level.AssetFormat) {
		var a = Manager.ME.createAsset(adata.t);
		a.setPos(adata.x, adata.y);
		a.dir = adata.d;
		a.applySerializedData(adata.data);
	}
	
	public function applySerializedData(data:Dynamic) {
	}
	
	
	public static function highlight(a:Asset) {
		if( HIGHLIGHTED==a )
			return;
			
		clearHighlight();
		HIGHLIGHTED = a;
		a.sprite.filters = [
			new flash.filters.GlowFilter(Const.THEME.ui,1, 2,2, 4),
			new flash.filters.GlowFilter(Const.THEME.ui,0.6, 16,16, 2),
		];
	}
	
	public static function clearHighlight() {
		if( HIGHLIGHTED!=null ) {
			HIGHLIGHTED.redraw();
			HIGHLIGHTED = null;
		}
	}
	

	public static function fromXml(data:haxe.xml.Fast) {
		var a = Manager.ME.createAsset( Type.createEnum(AssetType, data.att.t) );
		a.setPos( Std.parseInt(data.att.x), Std.parseInt(data.att.y) );
		a.dir = Std.parseInt(data.att.d);
	}
	
	
	public function destroy() {
		sprite.parent.removeChild(sprite);
		ALL.remove(this);
	}
	
	public function updateDirection() {
		sprite.rotation = dir*90;
		switch( dir ) {
			case 0 :
			case 1 :
				sprite.x+=Const.GRID;
			case 2 :
				sprite.x+=Const.GRID;
				sprite.y+=Const.GRID;
			case 3 :
				sprite.y+=Const.GRID;
		}
		
	}
	
	public function update() {
		var pt = man.level.gridToGlobal(cx,cy);
		sprite.x = pt.x;
		sprite.y = pt.y;
		updateDirection();
	}
}

