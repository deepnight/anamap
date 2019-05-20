package as;

class Stair extends Asset {
	public function new() {
		super();
	}
	
	override public function redraw() {
		super.redraw();
		sprite.graphics.clear();
		var rseed = getRandom();
		var n = 4;
		for( i in 0...n ) {
			var y = i * Const.GRID/(n);
			
			sprite.graphics.lineStyle(2, Const.THEME.wall, 0.6);
			sprite.graphics.moveTo(0, y);
			sprite.graphics.lineTo(Const.GRID, y);
			
			sprite.graphics.lineStyle(2, Const.THEME.wall, 0.4);
			sprite.graphics.moveTo(0, y+2);
			sprite.graphics.lineTo(Const.GRID, y+2);
		}
		sprite.filters = [
		];
	}
}
