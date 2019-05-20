package as;

class Furniture extends Asset {
	var wid			: Int;
	var hei			: Int;
	public function new(w,h) {
		super();
		wid = w;
		hei = h;
	}
	
	override public function isOver(x,y) {
		return switch( dir ) {
			case 0 : x>=cx && x<cx+wid && y>=cy && y<cy+hei;
			case 1 : x>cx-hei && x<=cx && y>=cy && y<cy+wid;
			case 2 : x>cx-wid && x<=cx && y>cy-hei && y<=cy;
			case 3 : x>=cx && x<cx+hei && y>cy-wid && y<=cy;
			default : false;
		}
	}
	override public function redraw() {
		super.redraw();
		sprite.graphics.clear();
		sprite.graphics.lineStyle(1,Const.THEME.asset, 0.7);
		sprite.graphics.beginFill(Const.THEME.asset, 0.1);
		sprite.graphics.drawRect(Const.GRID*0.1, Const.GRID*0.1, Const.GRID*(wid-1+0.8), Const.GRID*(hei-1+0.8));
	}
}
