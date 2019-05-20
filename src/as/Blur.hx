package as;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;

class Blur extends Asset {
	static var MASK : BitmapData = null;
	
	var draftSprite		: Sprite;
	
	public function new() {
		super();
		sprite.filters = [];
		
		if( MASK==null )
			initMask();
			
		var bmp = new Bitmap(MASK);
		bmp.x = -bmp.width*0.5 + Const.GRID*0.5 + 2;
		bmp.y = -bmp.height*0.5 + Const.GRID*0.5;
		sprite.addChild(bmp);
		
		draftSprite = new Sprite();
		sprite.addChild(draftSprite);
		draftSprite.visible = draftMode;
	}
	
	function initMask() {
		var pt0 = new flash.geom.Point(0,0);
		
		// Core mask
		var b = 8;
		var r = Std.int(Const.GRID*1);
		
		var s = new flash.display.Sprite();
		s.graphics.beginFill(Const.THEME.bg);
		s.graphics.drawCircle(b+r, b+r, r);
		
		var core = new BitmapData(b*2+r*2, b*2+r*2, true, 0x0);
		core.draw(s);
		core.applyFilter(core, core.rect, pt0, new flash.filters.BlurFilter(b,b));
		
		// Stripes
		var b = 32;
		var r = Std.int(Const.GRID*1.6);
		
		var s = new flash.display.Sprite();
		s.graphics.beginFill(0x00FF00);
		s.graphics.drawCircle(b+r, b+r, r);
		
		var smask = new BitmapData(b*2+r*2, b*2+r*2, true, 0x0);
		smask.draw(s);
		smask.applyFilter(smask, smask.rect, pt0, new flash.filters.BlurFilter(b,b));

		var stripes = man.level.createStripeTexture(b*2+r*2, b*2+r*2);
		
		// Final assemble
		if( MASK==null )
			MASK = new BitmapData(b*2+r*2, b*2+r*2, true, 0x0);
		else
			MASK.fillRect(MASK.rect, 0x0);
		MASK.copyPixels(core, core.rect, new flash.geom.Point(MASK.width*0.5-core.width*0.5, MASK.height*0.5-core.height*0.5));
		
		if( man.level.showStripes )
			MASK.copyPixels(stripes, stripes.rect, pt0, smask, true);
			
		core.dispose();
		smask.dispose();
		stripes.dispose();
	}
	
	//override function onThemeChange() {
		//initMask();
		//super.onThemeChange();
	//}
	
	override function set_draftMode(b) {
		if( draftSprite!=null )
			draftSprite.visible = b;
		return super.set_draftMode(b);
	}
	override function redraw() {
		super.redraw();
		initMask();
		sprite.graphics.clear();
		
		draftSprite.graphics.clear();
		draftSprite.graphics.lineStyle(4, Const.THEME.wall, 1);
		draftSprite.graphics.moveTo(Const.GRID*0.2, Const.GRID*0.2);
		draftSprite.graphics.lineTo(Const.GRID*0.8, Const.GRID*0.8);
		draftSprite.graphics.moveTo(Const.GRID*0.8, Const.GRID*0.2);
		draftSprite.graphics.lineTo(Const.GRID*0.2, Const.GRID*0.8);
	}
	
	//override function destroy() {
		//super.destroy();
		//result.dispose();
	//}
}
