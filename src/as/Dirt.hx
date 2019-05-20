package as;

class Dirt extends Asset {
	var big		: Bool;
	public function new(big:Bool) {
		super();
		this.big = big;
	}
	
	override public function redraw() {
		super.redraw();
		sprite.graphics.clear();
		var rseed = getRandom();
		for( i in 0...12 ) {
			if( big ) {
				sprite.graphics.lineStyle(1, Const.THEME.wall, 0.3);
				sprite.graphics.beginFill(Const.THEME.bg, 0.7);
				sprite.graphics.drawCircle(rseed.range(Const.GRID*0.1, Const.GRID*0.9), rseed.random(Const.GRID), rseed.range(1,4));
			}
			else {
				var w = rseed.irange(2,3);
				sprite.graphics.beginFill(Const.THEME.wall, 0.2);
				sprite.graphics.drawRect(rseed.random(Const.GRID-w), rseed.random(Const.GRID-w), w, w);
			}
		}
		
		if( big )
			sprite.filters = [
				new flash.filters.GlowFilter(Const.THEME.wall, 0.7, 2,2,4),
				new flash.filters.DropShadowFilter(4,-90, Const.THEME.wall, 0.3, 0,0,1, 1,true),
			];
	}
}
