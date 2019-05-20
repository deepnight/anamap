package as;

class Tree extends Asset {
	public function new() {
		super();
	}
	
	override public function redraw() {
		super.redraw();
		sprite.graphics.clear();
		var rseed = getRandom();
		for( i in 0...10 ) {
			sprite.graphics.beginFill(mt.deepnight.Color.brightnessInt(Const.THEME.vegetal,0.2), 0.7);
			sprite.graphics.drawCircle(rseed.random(Const.GRID), rseed.random(Const.GRID), rseed.range(4,6));
		}
		sprite.filters = [
			new flash.filters.GlowFilter(Const.THEME.vegetal,0.7, 2,2, 4),
		];
	}
}
