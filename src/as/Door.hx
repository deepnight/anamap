package as;

class Door extends Asset {
	public function new() {
		super();
	}

	override public function redraw() {
		super.redraw();
		sprite.graphics.clear();
		sprite.graphics.beginFill(Const.THEME.door, 0.75);
		sprite.graphics.drawRect(-Const.GRID*0.1, Const.GRID*0.3, Const.GRID*1.2, Const.GRID*0.4);
	}
}