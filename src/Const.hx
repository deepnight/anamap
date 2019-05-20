class Const {
	public static var TITLE = "ANAmap";
	public static var VERSION = 7.1;

	public static var WID = Std.int(flash.Lib.current.stage.stageWidth);
	public static var HEI = Std.int(flash.Lib.current.stage.stageHeight);
	
	static var inc = 0;
	public static var DP_LEVEL = inc++;
	public static var DP_ASSET = inc++;
	public static var DP_TEXT = inc++;
	public static var DP_CURSOR = inc++;
	public static var DP_INTERF = inc++;
	public static var DP_PALETTE = inc++;
	
	public static var THEMES : Map<String, Theme> = initThemes();
	public static var THEME = THEMES.get("light");
	
	public static var GRID = 16;
	
	public static var RED_BUTTON = 0x711122;
	
	
	static function initThemes() {
		var h : Map<String,Theme> = [
			"light" => {
				id		: "light",
				bg		: 0xF0EBE6,
				wall	: 0x786249,
				door	: 0x52321D,
				asset	: 0x38598B,
				vegetal	: 0x5C873D,
				stripes	: 0xB8A289,
				ui		: 0xFF9300,
			},
			"dark" => {
				id		: "dark",
				bg		: 0x2D354D,
				wall	: 0x9EA9C7,
				door	: 0xBF9477,
				asset	: 0xDAC987,
				vegetal	: 0x456B53,
				stripes	: 0x445275,
				ui		: 0xFF9300,
			},
			"print" => {
				id		: "print",
				bg		: 0xFFFFFF,
				wall	: 0x000000,
				door	: 0x606060,
				asset	: 0x4A4A4A,
				vegetal	: 0x838383,
				stripes	: 0xC9C9C9,
				ui		: 0x000000,
			},
		];
		return h;
	}
}

typedef Theme = {
	var id		: String;
	var bg		: Int;
	var wall	: Int;
	var door	: Int;
	var asset	: Int;
	var vegetal	: Int;
	var stripes	: Int;
	var ui		: Int;
}

typedef Settings = {
	var lang			: String;
	var exportGrid		: Bool;
	var exportStripes	: Bool;
	var printBW			: Bool;
	var printScale		: Float;
}

enum Tool {
	TGround;
	TAsset(a:AssetType);
	TText;
}

enum Cursor {
	CurAddGround;
	CurRemoveGround;
	
	CurAsset;
	CurText;
	
	CurPainting;
	CurRemovingAsset;
	//CurAdd;
	//CurRemove;
}

enum AssetType {
	@internal AUnknown;
	ADoor;
	ASmallDirt;
	ABigDirt;
	ACrate;
	ASmallFurn;
	AFurn_1x1;
	AFurn_2x1;
	AFurn_3x1;
	AFurn_4x1;
	AFurn_2x2;
	AFurn_3x2;
	AFurn_4x2;
	ATree;
	ABlur;
	@internal AText;
	AStair;
}