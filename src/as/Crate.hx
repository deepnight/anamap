package as;

class Crate extends Asset {
	public function new() {
		super();
	}
	
	override function redraw() {
		super.redraw();
		var rseed = getRandom();
		sprite.graphics.clear();
		
		sprite.graphics.beginFill(Const.THEME.bg, 1);
		sprite.graphics.lineStyle(1, Const.THEME.asset, 0.4);
		sprite.graphics.drawRect(rseed.range(0,Const.GRID*0.3), rseed.range(0,Const.GRID*0.3), Const.GRID*0.6, Const.GRID*0.6);
		
		sprite.graphics.beginFill(Const.THEME.bg, 1);
		sprite.graphics.lineStyle(1, Const.THEME.asset, 0.4);
		sprite.graphics.drawRect(rseed.range(0,Const.GRID*0.6), rseed.range(0,Const.GRID*0.6), Const.GRID*0.4, Const.GRID*0.4);
	}
}
