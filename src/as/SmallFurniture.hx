package as;

class SmallFurniture extends Asset {
	public function new() {
		super();
	}
	
	override public function redraw() {
		super.redraw();
		sprite.graphics.clear();
		sprite.graphics.lineStyle(1,Const.THEME.asset, 0.7);
		sprite.graphics.beginFill(Const.THEME.asset, 0.1);
		sprite.graphics.drawRect(Const.GRID*0.3, Const.GRID*0.3, Const.GRID*0.4, Const.GRID*0.4);
	}
}
