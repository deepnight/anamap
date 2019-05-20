import mt.deepnight.Buffer;
import mt.deepnight.SpriteLibBitmap;
import mt.deepnight.mui.*;

import mt.MLib;
import mt.flash.Key;

import flash.ui.Keyboard;
import flash.display.Sprite;

import Const;

@:bitmap("gfx/tiles.png") class GfxTiles extends flash.display.BitmapData {}
@:bitmap("gfx/logo.png") class GfxLogo extends flash.display.BitmapData {}

@:publicFields class Manager { //}
	public static var ME : Manager;

	var root		: flash.display.MovieClip;
	var tiles		: SpriteLibBitmap;

	var settings	: Settings;
	var tool		: Tool;
	var removeGround: Bool;
	var removeAssets: Bool;
	var rectSel		: Null<{cx:Int, cy:Int, wid:Int, hei:Int}>;
	var clicking	: Bool;
	var outside		: Bool;
	var locked		: Bool;
	var lastCoord	: Null<{cx:Int, cy:Int}>;
	var dragStart	: Null<{x:Float, y:Float}>;

	var level		: Level;
	var cursor		: Sprite;
	var assetCursor	: Null<Asset>;
	var selectedAsset: Null<Asset>;
	var rectWrapper	: Sprite;
	var uiWrapper	: Sprite;
	var menu		: HGroup;
	var palette		: VGroup;
	var tip			: VGroup;
	var contextUI	: Group;
	var draftBt		: Check;
	var themeBt		: Check;

	var dm			: mt.flash.DepthManager;
	var cd			: mt.Cooldown;
	var tw			: mt.deepnight.Tweenie;

	public function new(r) {
		mt.deepnight.Lib.redirectTracesToConsole();

		settings = getSettings();

		ME = this;
		root = r;
		root.addEventListener( flash.events.Event.ENTER_FRAME, main );
		root.stage.quality = flash.display.StageQuality.LOW;

		locked = false;
		outside = true;
		clicking = false;
		tool = TGround;
		removeAssets = removeGround = false;

		cd = new mt.Cooldown();
		tw = new mt.deepnight.Tweenie();
		dm = new mt.flash.DepthManager(root);

		Key.init();
		Tx.init( haxe.Resource.getString(settings.lang) );


		// Tilesheet
		tiles = new SpriteLibBitmap( new GfxTiles(0,0) );
		tiles.setSliceGrid(16,16);
		tiles.sliceGrid("stripes", 0,0);

		level = new Level();
		dm.add(level.render, Const.DP_LEVEL);


		// Cursor
		cursor = new Sprite();
		dm.add(cursor, Const.DP_CURSOR);
		cursor.mouseChildren = cursor.mouseEnabled = false;
		setCursor(CurAddGround);

		// Rectangular selection
		rectWrapper = new Sprite();
		dm.add(rectWrapper, Const.DP_CURSOR);
		rectWrapper.mouseChildren = cursor.mouseEnabled = false;
		rectWrapper.filters = [ new flash.filters.GlowFilter(0xFF4D00,1, 8,8,2) ];

		// Main UI
		Component.BG_COLOR = 0x1E1F2D;
		Button.BG_COLOR = 0x424464;
		Check.BG_COLOR = 0x5B433C;
		Window.CLICKTRAP_COLOR = 0x373953;
		Window.CLICKTRAP_ALPHA = 0.8;
		uiWrapper = new Sprite();
		dm.add(uiWrapper, Const.DP_INTERF);

		menu = new HGroup(uiWrapper);
		menu.removeBorders();

		// Contextual edit UI
		contextUI = new VGroup(uiWrapper);
		contextUI.hide();

		// Tool palette
		palette = new VGroup(uiWrapper, 2);
		palette.setPos(0,40);

		// Tooltip
		tip = new VGroup(uiWrapper, 0, 8);
		tip.x = 5;

		initUI();
		level.setDraftMode(true);

		// Intro pop up
		showAbout();

		// Events
		level.render.addEventListener( flash.events.MouseEvent.MOUSE_DOWN, onMouseDown );
		root.addEventListener( flash.events.MouseEvent.MOUSE_UP, onMouseUp );

		root.addEventListener( flash.events.MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown );
		root.addEventListener( flash.events.MouseEvent.RIGHT_MOUSE_UP, onRightMouseUp );
		root.stage.addEventListener( flash.events.Event.MOUSE_LEAVE, onMouseLeave);

		root.addEventListener( flash.events.MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleDown);
		root.addEventListener( flash.events.MouseEvent.MIDDLE_MOUSE_UP, onMiddleUp);

		root.addEventListener( flash.events.MouseEvent.MOUSE_MOVE, onMouseMove);

		// Reload last level
		level.loadState();
		level.saveState();

		#if debug
		var debug = new mt.flash.Stats(Const.WID-70);
		root.addChild(debug);
		#end
	}


	function getSettings() : Settings {
		var def : Settings = {
			lang			: "en",
			exportGrid		: true,
			exportStripes	: true,
			printBW			: false,
			printScale		: 0.5,
		}
		var s : Settings = mt.deepnight.Lib.getCookie("rpgMap", "settings", def);
		return s;
	}


	function saveSettings() {
		mt.deepnight.Lib.setCookie("rpgMap", "settings", settings);
	}


	function initUI() {
		// Main menu
		menu.removeAllChildren();
		var g = new HGroup(menu);
		new Button(g, Tx.Load, level.loadData);
		new Button(g, Tx.Save, level.saveData);
		new Button(g, Tx.ExportImage, showImageSettings);
		new Button(g, Tx.Print, showPrintSettings);

		var g = new HGroup(menu);
		new Button(g, Tx.Cancel, cancel);
		new Button(g, Tx.Reset, showResetSettings);

		var g = new HGroup(menu);
		draftBt = new Check(g, Tx.Draft, level.draftMode, function(v) {
			level.setDraftMode(v);
		});
		themeBt = new Check(g, Tx.Theme, function(v) {
			setTheme( v ? "dark" : "light" );
			level.saveState();
		});

		var g = new HGroup(menu);
		new Button(g, Tx.Help, showHelp);
		new Button(g, Tx.Options, showOptions);
		new Button(g, Tx.Samples, showSamples);


		// Tool palette
		palette.removeAllChildren();
		new Radio(palette, Tx.Tool_Ground, function(v) if(v) selectTool(TGround));
		new Radio(palette, Tx.Tool_Text, function(v) if(v) selectTool(TText));

		new Label(palette, Tx.Assets);
		for(k in Type.getEnumConstructs(AssetType)) {
			var e = Type.createEnum(AssetType, k);
			var meta = Reflect.field( haxe.rtti.Meta.getFields(AssetType), k );
			if( meta==null || !Reflect.hasField(meta, "internal") ) {
				var label = Std.string(e).substr(1);
				new Radio(palette, label, function(v) if(v) selectTool(TAsset(e)));
			}
		}

	}

	function setLang(k) {
		settings.lang = k;
		Tx.init( haxe.Resource.getString(settings.lang) );
	}


	function selectTool(t:Tool) {
		tool = t;
		Asset.clearHighlight();

		if( assetCursor!=null ) {
			assetCursor.destroy();
			assetCursor = null;
		}

		switch( tool ) {
			case TAsset(at) :
				setTip(Tx.TipAsset);
				assetCursor = createAsset(at);
				assetCursor.setAsCursor();
				assetCursor.redraw();
				cursor.addChild(assetCursor.sprite);

			case TGround :
				setTip(Tx.TipGround);

			case TText :
				setTip(Tx.TipText);
		}
	}

	public function setTheme(id:String) {
		if( !Const.THEMES.exists(id) ) {
			notify("Unknown theme "+id); // TODO
			return;
		}

		if( id=="dark" )
			themeBt.select();
		else
			themeBt.unselect();

		Const.THEME = Const.THEMES.get(id);
		level.applyTheme();
		level.redraw();
		for(a in Asset.ALL)
			a.onThemeChange();
	}

	public function createField(str:String, ?size=13, ?autoSize=true) {
		var tf = new flash.text.TextField();
		var f = new flash.text.TextFormat("default", size);
		tf.setTextFormat(f);
		tf.defaultTextFormat = f;
		tf.text = str;
		tf.width = 300;
		tf.height = 300;
		tf.embedFonts = true;
		if( autoSize ) {
			tf.width = tf.textWidth+5;
			tf.height = tf.textHeight+4;
		}
		tf.wordWrap = tf.multiline = false;
		tf.selectable = tf.mouseEnabled = false;
		tf.textColor = Const.THEME.wall;
		tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
		return tf;
	}

	public function setTip(?raw:String) {
		if( raw==null )
			tip.hide();
		else {
			tip.show();
			tip.removeAllChildren();
			for(s in raw.split("|")) {
				var l = new Label(tip, StringTools.trim(s));
				l.minHeight = 0;
				l.setAlign(Left);
			}
		}
		if( tip.x!=5 )
			tip.x = Const.WID - tip.getWidth() - 5;
		tip.y = Const.HEI - tip.getHeight() - 5;
	}



	public function notify(str:String) {
		var wrapper = new Sprite();
		dm.add(wrapper, Const.DP_INTERF);
		wrapper.mouseChildren = wrapper.mouseEnabled = false;

		var tf = createField(str, str.length>80 ? 14 : 16);
		tf.textColor = 0xFFFFFF;
		wrapper.addChild(tf);

		wrapper.graphics.beginFill(0x0, 0.75);
		wrapper.graphics.drawRect(-10,-10, tf.width+20,tf.height+20);
		wrapper.x = Std.int(Const.WID*0.5 - wrapper.width*0.5);
		wrapper.y = Const.HEI;

		tw.create(wrapper, "y", Const.HEI-wrapper.height, 200).onEnd = function() {
			haxe.Timer.delay( function() {
				tw.create(wrapper, "y", Const.HEI, 200).onEnd = function() {
					wrapper.parent.removeChild(wrapper);
				}
			}, 1000 + str.length*25);
		};
	}


	function showSamples() {
		var w = new Window(uiWrapper);

		new Label(w, Tx.Samples);

		new Button(w, Tx.SampleIn, function() {
			level.load( haxe.Resource.getString("sample_in") );
			notify(Tx.SampleLoaded);
			w.destroy();
		});

		new Button(w, Tx.SampleOut, function() {
			level.load( haxe.Resource.getString("sample_out") );
			notify(Tx.SampleLoaded);
			w.destroy();
		});

		new Button(w, Tx.SampleCthulhu, function() {
			level.load( haxe.Resource.getString("sample_cthulhu") );
			notify(Tx.SampleLoaded);
			w.destroy();
		});


		var b = new Button(w, Tx.Close, function() {
			w.destroy();
		});
		b.color = Const.RED_BUTTON;
	}


	function showOptions() {
		var w = new Window(uiWrapper);

		var g = new HGroup(w);
		new Label(g, Tx.Lang);
		new Radio(g, "FR", settings.lang=="fr", function(v) if(v) setLang("fr"));
		new Radio(g, "EN", settings.lang=="en", function(v) if(v) setLang("en"));

		//var g = new VGroup(w);
		//new Label(g, Tx.Options);
		//new Check(g, Tx.ExportGridSetting, settings.exportGrid, function(v) settings.exportGrid = v);

		var b = new Button(w, Tx.Close, function() {
			initUI();
			saveSettings();
			w.destroy();
		});
		b.color = Const.RED_BUTTON;
	}



	function showResetSettings() {
		var w = new Window(uiWrapper);

		/*
		new Label(w, "Delete everything and...");

		var b = new Button(w, "...fill the map with walls", function() {
			w.destroy();
			clearAll(true);
		});
		b.color = Const.RED_BUTTON;

		var b = new Button(w, "...fill the map with empty space", function() {
			w.destroy();
			clearAll(false);
		});
		b.color = Const.RED_BUTTON;
		*/

		new Button(w, Tx.Reset, function() {
			w.destroy();
			clearAll(true);
		});

		var b = new Button(w, Tx.Cancel, function() {
			w.destroy();
		});
		b.color = Const.RED_BUTTON;
	}


	function showImageSettings() {
		if( level.isEmpty() ) {
			notify(Tx.EmptyLevel);
			return;
		}

		var w = new Window(uiWrapper);

		new Label(w, Tx.ExportImage);

		var g = new VGroup(w);
		new Check(g, Tx.ExportGrid, settings.exportGrid, function(v) settings.exportGrid = v);
		new Check(g, Tx.ExportStripes, settings.exportStripes, function(v) settings.exportStripes = v);

		new Button(w, Tx.Ok, function() {
			saveSettings();
			level.savePNG();
			w.destroy();
		});
		var b = new Button(w, Tx.Cancel, function() {
			w.destroy();
		});
		b.color = Const.RED_BUTTON;
	}


	function showPrintSettings() {
		if( level.isEmpty() ) {
			notify(Tx.EmptyLevel);
			return;
		}
		var w = new Window(uiWrapper);

		new Label(w, Tx.Print);

		var g = new HGroup(w);
		new Label(g, Tx.PrintSize);
		new Radio(g, Tx.PrintSizeNormal, settings.printScale==0.5, function(v) if(v) settings.printScale = 0.5);
		new Radio(g, Tx.PrintSizeLarge, settings.printScale==1, function(v) if(v) settings.printScale = 1);

		var g = new VGroup(w);
		new Check(g, Tx.ExportGrid, settings.exportGrid, function(v) settings.exportGrid = v);
		new Check(g, Tx.ExportStripes, settings.exportStripes, function(v) settings.exportStripes = v);
		new Check(g, Tx.PrintBW, settings.printBW, function(v) settings.printBW = v);

		new Button(w, Tx.Ok, function() {
			saveSettings();
			level.print();
			w.destroy();
		});
		var b = new Button(w, Tx.Cancel, function() {
			w.destroy();
		});
		b.color = Const.RED_BUTTON;
	}


	function gotoUrl(url) {
		level.saveState();
		var r = new flash.net.URLRequest(url);
		flash.Lib.getURL(r, "_blank");
	}


	function showAbout() {
		var w = new Window(uiWrapper, function(w) w.destroy());
		var bd = new GfxLogo(0,0);
		new Image(w, new flash.display.Bitmap(bd), function() {
			bd.dispose();
		});
		new Label(w, Tx.Version({_v:Const.VERSION, _title:Const.TITLE}) );

		var g = new HGroup(w);
		g.removeBorders();
		new Button(g, Tx.HomePage, gotoUrl.bind("http://deepnight.net") ).minWidth = 150;
		new Button(g, "Twitter", gotoUrl.bind("http://twitter.com/deepnightfr") ).minWidth = 150;
		var b = new Button(g, Tx.Help, showHelp).minWidth = 150;

		var b = new Button(w, Tx.Close, function() {
			w.destroy();
		});
		b.color = Const.RED_BUTTON;
		b.minHeight = 40;

		w.wrapper.addEventListener( flash.events.MouseEvent.CLICK, function(_) {
			w.destroy();
		});
	}


	function showHelp() {
		locked = true;
		hideCursor();

		var w = new Window(uiWrapper);

		var t = new TextInput(w);
		t.setWidth(600);
		t.setHeight(350);
		t.multiLine = true;
		t.readOnly = true;
		t.setFont("Courier new");

		var raw = StringTools.replace( Tx.HelpContent({
			_ground	: Tx.TipGround,
			_text	: Tx.TipText,
			_asset	: Tx.TipAsset,
		}), "|", "\n");
		var lines = raw.split("\n");
		lines.shift();
		for(line in lines) {
			line = StringTools.trim(line);
			t.addLine(line);
		}

		function close() {
			w.destroy();
			locked = false;
			showCursor();
		}

		new Button(w, Tx.About({_title:Const.TITLE}), function() {
			close();
			showAbout();
		});
		var b = new Button(w, Tx.Close, close);
		b.color = Const.RED_BUTTON;
	}


	inline function getMouse() {
		var pt = level.globalToGrid(root.mouseX, root.mouseY);
		return {
			x	: root.mouseX,
			y	: root.mouseY,
			cx	: pt.cx,
			cy	: pt.cy,
		}
	}

	function onRightMouseDown(_) {
		if( locked )
			return;

		clearContextUI();
		removeAssets = true;
		clicking = true;
	}

	function onRightMouseUp(_) {
		if( locked )
			return;

		clicking = false;
	}


	function onMouseDown(_) {
		if( locked )
			return;

		var m = getMouse();
		clicking = true;
		clearContextUI();
		removeAssets = removeGround = false;


		switch( tool ) {
			case TGround :
				if( Key.isDown(Keyboard.SHIFT) )
					rectSel = { cx:m.cx, cy:m.cy, wid:1, hei:1 };
				removeGround = level.isGround(m.cx, m.cy);

			case TAsset(_) :

			case TText :
				var a = getLabelAt(m.cx, m.cy);
				if( a!=null ) {
					// Edit previous text
					editText(a);
				}
				else {
					// New text
					var a : as.Text = cast createAsset(AText);
					a.setPos(m.cx, m.cy);
					a.redraw();
					editText(a);
				}
		}
	}

	function onMouseUp(_) {
		if( locked )
			return;

		if( rectSel!=null ) {
			// Draw rectangular area
			if( rectSel.wid<0 ) {
				rectSel.wid = MLib.iabs(rectSel.wid);
				rectSel.cx-=rectSel.wid;
			}
			if( rectSel.hei<0 ) {
				rectSel.hei = MLib.iabs(rectSel.hei);
				rectSel.cy-=rectSel.hei;
			}
			for(cx in rectSel.cx...rectSel.cx+rectSel.wid)
				for(cy in rectSel.cy...rectSel.cy+rectSel.hei) {
					level.setGround( cx, cy, !removeGround );
				}

			level.invalidateBounds();
			level.redraw();
			autoSave();
		}

		clicking = false;
		lastCoord = null;
		rectSel = null;
		rectWrapper.graphics.clear();
	}

	function onMouseMove(_) {
		if( outside ) {
			showCursor();
			outside = false;
		}
	}

	function onMouseLeave(_) {
		onMouseUp(null);
		onMiddleUp(null);
		outside = true;
		hideCursor();
	}

	function onMiddleDown(_) {
		dragStart = getMouse();
	}

	function onMiddleUp(_) {
		dragStart = null;
	}


	function editText(ta:as.Text) {
		clearContextUI();
		contextUI.show();

		selectedAsset = ta;

		var tf = new TextInput(contextUI, ta.getText(), function(s) {
			ta.setText(s);
			level.saveState();
		});
		tf.focus();

		// Size
		var g = new HGroup(contextUI);
		new Label(g, Tx.FontSize);
		var s = ta.getSize();
		new Radio(g, Tx.FontSmall, s==0, function(v) if(v) {autoSave(); ta.setSize(0);});
		new Radio(g, Tx.FontMedium, s==1, function(v) if(v) {autoSave(); ta.setSize(1);});
		new Radio(g, Tx.FontBig, s==2, function(v) if(v) {autoSave(); ta.setSize(2);});

		// Align
		var g = new HGroup(contextUI);
		new Label(g, Tx.Align);
		new Radio(g, Tx.AlignLeft, ta.align==A_Left, function(v) if(v) {autoSave(); ta.setAlign(A_Left);} );
		new Radio(g, Tx.AlignCenter, ta.align==A_Center, function(v) if(v) {autoSave(); ta.setAlign(A_Center);} );
		new Radio(g, Tx.AlignRight, ta.align==A_Right, function(v) if(v) {autoSave(); ta.setAlign(A_Right);} );

		// Actions
		new Button(contextUI, Tx.Ok, clearContextUI);
		var b = new Button(contextUI, Tx.Delete, function(){
			ta.destroy();
			level.saveState();
			clearContextUI();
		});
		b.color = Const.RED_BUTTON;
	}

	function clearContextUI() {
		contextUI.removeAllChildren();
		contextUI.hide();
		selectedAsset = null;
	}


	function setCursor(c:Cursor) {
		cursor.graphics.clear();
		if( assetCursor!=null )
			assetCursor.sprite.visible = false;

		switch( c ) {

			case CurPainting :
				cursor.alpha = 1;
				cursor.graphics.lineStyle(1, 0xFFFF00, 1);
				cursor.graphics.drawRect(0,0,Const.GRID, Const.GRID);
				cursor.filters = [ new flash.filters.GlowFilter(0xFF4D00,1, 8,8,2) ];

			case CurRemovingAsset :
				cursor.alpha = 1;
				cursor.graphics.lineStyle(1, 0xFF3900, 1);
				cursor.graphics.drawRect(0,0,Const.GRID, Const.GRID);
				cursor.filters = [ new flash.filters.GlowFilter(0xC10000,1, 8,8,2) ];

			case CurAddGround :
				cursor.alpha = 0.8;
				cursor.graphics.beginFill( Const.THEME.bg, 1 );
				cursor.graphics.drawRect(Const.GRID*0.05, Const.GRID*0.05, Const.GRID*0.9, Const.GRID*0.9);
				cursor.filters = [
					new flash.filters.GlowFilter(0x0, 0.6, 8,8,1, 1,true),
					new flash.filters.DropShadowFilter(2,-90, Const.THEME.wall, 0.5, 0,0),
				];

			case CurRemoveGround :
				cursor.alpha = 0.6;
				cursor.graphics.beginFill( Const.THEME.bg, 1 );
				cursor.graphics.drawRect(Const.GRID*0.1, Const.GRID*0.1, Const.GRID*0.8, Const.GRID*0.8);
				cursor.filters = [
					new flash.filters.GlowFilter(Const.THEME.wall, 0.5, 2,2,4, 1,true),
					new flash.filters.DropShadowFilter(3,90, Const.THEME.wall, 0.6, 0,0),
					new flash.filters.GlowFilter(0x0, 0.15, 8,8,2),
				];

			case CurAsset :
				assetCursor.sprite.visible = true;
				cursor.alpha = 0.6;
				cursor.filters = [];

			case CurText :
				//cursor.alpha = 0.6;
				//cursor.filters = [];
		}
	}


	function getLabelAt(cx,cy) : as.Text {
		for(ta in as.Text.ALL)
			if( ta.isOver(cx,cy) )
				return ta;

		return null;
	}


	function getAssetAt(cx,cy) : Asset {
		for(a in Asset.ALL)
			if( a.isOver(cx,cy) )
				return a;

		return null;
	}


	function createAsset(at:AssetType) : Asset {
		if( at==null )
			at = AUnknown;
		var a = switch( at ) {
			case AUnknown :
				var a = new Asset();
				a.useErrorRender = true;
				a.redraw();
				a;

			case ADoor : new as.Door();
			case ASmallDirt : new as.Dirt(false);
			case ABigDirt : new as.Dirt(true);
			case ACrate : new as.Crate();
			case AFurn_1x1 : new as.Furniture(1,1);
			case AFurn_2x1 : new as.Furniture(2,1);
			case AFurn_3x1 : new as.Furniture(3,1);
			case AFurn_4x1 : new as.Furniture(4,1);
			case AFurn_2x2 : new as.Furniture(2,2);
			case AFurn_3x2 : new as.Furniture(3,2);
			case AFurn_4x2 : new as.Furniture(4,2);
			case ATree : new as.Tree();
			case ABlur : new as.Blur();
			case ASmallFurn : new as.SmallFurniture();
			case AText : new as.Text();
			case AStair : new as.Stair();
		}
		a.type = at;
		return a;
	}

	public inline function showCursor() {
		if( !locked )
			cursor.visible = true;
	}
	public inline function hideCursor() {
		cursor.visible = false;
	}


	function autoSave() {
		cd.set("autoSave", 8);
		cd.onComplete("autoSave", level.saveState);
	}

	function clearAll(walls:Bool) {
		clearContextUI();
		level.initMap(walls);
		level.saveState();
		notify(Tx.ResetDone);
	}

	function cancel() {
		level.cancel();
		clearContextUI();
	}


	function main(_) {
		var m = getMouse();

		if( !locked ) {
			if( Key.isToggled(Keyboard.LEFT) ) {
				level.pan(1,0);
				autoSave();
			}

			if( Key.isToggled(Keyboard.RIGHT) ) {
				level.pan(-1,0);
				autoSave();
			}

			if( Key.isToggled(Keyboard.UP) ) {
				level.pan(0,1);
				autoSave();
			}

			if( Key.isToggled(Keyboard.DOWN) ) {
				level.pan(0,-1);
				autoSave();
			}

			if( Key.isDown(Keyboard.CONTROL) )
				if( Key.isToggled(Keyboard.Z) )
					cancel();

			if( assetCursor!=null && (Key.isToggled(Keyboard.SPACE) || Key.isToggled(Keyboard.R)) ) {
				assetCursor.rotate();
				assetCursor.sprite.x = 0;
				assetCursor.sprite.y = 0;
				assetCursor.updateDirection();
			}
		}


		if( level.isValid(m.cx, m.cy) ) {
			var cx = m.cx;
			var cy = m.cy;
			var gpt = level.gridToGlobal(cx,cy);
			cursor.x = gpt.x;
			cursor.y = gpt.y;
			if( clicking ) {
				if( rectSel!=null ) {
					// Rectangular selection
					var w = cx-rectSel.cx;
					var h = cy-rectSel.cy;
					if( rectSel.wid>0 && w<0 )
						rectSel.cx++;

					if( rectSel.wid<0 && w>=0 )
						rectSel.cx--;

					if( rectSel.hei>0 && h<0 )
						rectSel.cy++;

					if( rectSel.hei<0 && h>=0 )
						rectSel.cy--;

					rectSel.wid = w>=0 ? w+1 : w;
					rectSel.hei = h>=0 ? h+1 : h;
					rectWrapper.x = level.render.x + rectSel.cx*Const.GRID;
					rectWrapper.y = level.render.y + rectSel.cy*Const.GRID;
					rectWrapper.graphics.clear();
					rectWrapper.graphics.lineStyle(1, 0xFF9900, 1);
					rectWrapper.graphics.drawRect(0,0, rectSel.wid*Const.GRID, rectSel.hei*Const.GRID);
				}
				else {
					// Apply click action
					var needRedraw = false;
					var start = lastCoord!=null ? lastCoord : {cx:cx, cy:cy};
					var pts = mt.deepnight.Bresenham.getThinLine(start.cx, start.cy, cx,cy);
					for(pt in pts) {
						var cx = pt.x;
						var cy = pt.y;
						var a = getAssetAt(cx,cy);
						if( removeAssets ) {
							setCursor(CurRemovingAsset);
							if( a!=null )
								a.destroy();
						}
						else
							switch( tool ) {
								case TGround :
									setCursor(CurPainting);
									needRedraw = needRedraw || level.isGround(cx,cy) && removeGround || !level.isGround(cx,cy) && !removeGround;
									level.setGround(cx, cy, !removeGround);

								case TAsset(at) :
									if( a==null ) {
										var a = createAsset(at);
										a.setPos(cx,cy);
										a.dir = assetCursor.dir;
										needRedraw = true;
									}

								case TText :
							}
					};
					autoSave();
					if( needRedraw ) {
						level.invalidateBounds();
						level.redraw();
					}
				}
			}
			else {
				// Dynamically change cursor
				switch( tool ) {
					case TGround : setCursor( level.isGround(cx,cy) ? CurRemoveGround : CurAddGround );
					case TAsset(at) : setCursor( CurAsset );
					case TText :
						var a = getLabelAt(cx,cy);
						setCursor(CurText);
						if( a!=null )
							Asset.highlight(a);
						else
							Asset.clearHighlight();
				}
			}
			lastCoord = {cx:cx, cy:cy};
		}

		// Tooltip position
		if( m.y>=Const.HEI-200 && m.x<=300 ) {
			if( tip.x==5 )
				tip.x = Const.WID-tip.getWidth()-5;
		}
		else {
			if( tip.x!=5 )
				tip.x = 5;
		}

		// Mouse scrolling
		if( dragStart!=null ) {
			var m = getMouse();
			level.render.x += m.x-dragStart.x;
			level.render.y += m.y-dragStart.y;
			dragStart = m;
		}

		// Snap UI to selected asset
		if( selectedAsset!=null )
			contextUI.setPos(selectedAsset.sprite.x-30, selectedAsset.sprite.y+30);

		level.update();
		cd.update();
		tw.update();
		Component.updateAll();
	}
}


