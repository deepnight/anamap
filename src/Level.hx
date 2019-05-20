import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;
import mt.deepnight.HaxeJson;
import mt.deepnight.Lib;
import Const;

typedef SaveFormat = {
	var wid		: Int;
	var hei		: Int;
	var map		: String;
	var theme	: String;
	var assets	: Array<AssetFormat>;
}

typedef AssetFormat = {
	var t		: AssetType;
	var x		: Int;
	var y		: Int;
	var d		: Int;
	var data	: Null<Dynamic>;
}

class Level {
	public static var FORMAT_VERSION = 2;
	
	public var wid(default,null)	: Int;
	public var hei(default,null)	: Int;
	var man				: Manager;
	var map				: Array<Array<Bool>>;
	var lastName		: String;
	var lastBounds		: Null<{x1:Int, y1:Int, x2:Int, y2:Int}>;
	var history			: Array<String>;
	
	public var render		: Sprite;
	public var wallTexture	: Bitmap;
	public var grid			: Bitmap;
	public var bg			: Sprite;
	public var ground		: Sprite;
	
	public var draftMode	: Bool;
	public var showStripes	: Bool;
	
	public function new() {
		man = Manager.ME;
		wid = 128;
		hei = 128;
		history = [];
		draftMode = true;
		showStripes = true;
		
		render = new Sprite();
		render.addChild( bg = new Sprite() );
		render.addChild( wallTexture = new Bitmap() );
		render.addChild( ground = new Sprite() );
		render.addChild( grid = new Bitmap() );
		
		bg = new Sprite();
		man.dm.add(bg, Const.DP_LEVEL);
		//bg.graphics.beginFill(0x0, 0);
		//bg.graphics.drawRect(0,0, wid*Const.GRID, hei*Const.GRID);
		
		applyTheme();
			
		initMap();
	}
	
	public function applyTheme() {
		bg.graphics.clear();
		bg.graphics.beginFill(Const.THEME.bg, 1);
		bg.graphics.drawRect(0,0,Const.WID, Const.HEI);
		
		ground.filters = [
			new flash.filters.DropShadowFilter(4, 90, Const.THEME.wall, 0.5, 0,0,1, 1,true),
			new flash.filters.DropShadowFilter(2, 0, 0x0, 0.3, 8,4,1, 1,true),
			new flash.filters.GlowFilter(Const.THEME.wall,1, 2,2,10, 1,true),
			new flash.filters.GlowFilter(Const.THEME.wall,0.3, 32,32,1, 2),
		];
		
		if( wallTexture.bitmapData!=null )
			wallTexture.bitmapData.dispose();
		wallTexture.bitmapData = createStripeTexture( wid*Const.GRID, hei*Const.GRID );
		wallTexture.smoothing = true;
		
		// Draw grid
		if( grid.bitmapData!=null )
			grid.bitmapData.dispose();
		var s = new Sprite();
		s.graphics.lineStyle(1, Const.THEME.wall, 0.25);
		for(x in 0...wid+1) {
			s.graphics.moveTo(x*Const.GRID, 0);
			s.graphics.lineTo(x*Const.GRID, hei*Const.GRID);
		}
		for(y in 0...hei+1) {
			s.graphics.moveTo(0, y*Const.GRID);
			s.graphics.lineTo(wid*Const.GRID, y*Const.GRID);
		}
		grid.bitmapData = Lib.flatten(s).bitmapData;
	}
	
	public function createStripeTexture(w:Float, h:Float) {
		var w = Math.ceil(w);
		var h = Math.ceil(h);
		var bd = mt.deepnight.Lib.createTexture( man.tiles.getBitmapData("stripes"), w, h, true );
		//bd.applyFilter(bd, bd.rect, new flash.geom.Point(0,0), mt.deepnight.Color.getColorizeMatrixFilter(Const.THEME.wall, 1,0));
		//bd.colorTransform( bd.rect, new flash.geom.ColorTransform(1,1,1, Const.THEME.stripes) );
		var ct = new flash.geom.ColorTransform();
		ct.color = Const.THEME.stripes;
		bd.colorTransform( bd.rect, ct );
		return bd;
	}
	
	public function isEmpty() {
		var b = getBounds();
		return b.x1==wid && b.y1==hei;
	}
	
	
	public function initMap(?walls=true) {
		lastName = "map.json";
		
		while( Asset.ALL.length>0 )
			Asset.ALL[0].destroy();
		
		map = new Array();
		for(x in 0...wid) {
			map[x] = new Array();
			for(y in 0...hei)
				map[x][y] = walls;
		}
		
		redraw();
	}
	
	
	public inline function isValid(cx:Int,cy:Int) {
		return cx>=0 && cx<wid && cy>=0 && cy<hei;
	}
	
	public function globalToGrid(x:Float, y:Float) {
		return {
			cx	: Std.int( (x-render.x)/Const.GRID ),
			cy	: Std.int( (y-render.y)/Const.GRID ),
		}
	}
	
	public function gridToGlobal(cx:Int, cy:Int) {
		return {
			x	: render.x + cx*Const.GRID,
			y	: render.y + cy*Const.GRID,
		}
	}
	
	
	// JSON
	public function serializeJson() : String {
		var hj = new HaxeJson(FORMAT_VERSION);
		
		var smap = "";
		for(x in 0...wid)
			for(y in 0...hei)
				smap += map[x][y] ? 1 : 0;
		smap = compressRLE(smap);
		
		var save : SaveFormat = {
			wid		: wid,
			hei		: hei,
			map		: smap,
			theme	: Const.THEME.id,
			assets	: Asset.ALL.map( function(a) return a.serialize() ),
		}
		
		return hj.serialize(save);
	}
	
	public function unserializeJson(json:String) {
		var hj = new HaxeJson(FORMAT_VERSION);
		hj.unserialize(json);
		
		// v2: added new asset data field
		hj.patch(1,2, function(obj) {
			var obj : SaveFormat = cast obj;
			for(a in obj.assets)
				a.data = null;
		});
		
		var data : SaveFormat = hj.getUnserialized();
		
		// Map
		var idx = 0;
		data.map = uncompressRLE(data.map);
		for(x in 0...data.wid)
			for(y in 0...data.hei) {
				map[x][y] = data.map.charAt(idx)=="1";
				idx++;
			}
				
		// Assets
		for(a in data.assets)
			Asset.fromJson(a);
		

		invalidateBounds();
		redraw();
		man.setTheme( data.theme );
	}
	
	public function compressRLE(raw:String) {
		if( raw.length==0 )
			return "";
			
		var raw = raw.split("");
		var idx = 1;
		var out = "";
		var last = raw[0];
		var n = 1;
		
		function appendLast() {
			if( n<=5 )
				for(i in 0...n)
					out+=last;
			else
				out+="<"+n+":"+last+">";
		}
		
		while( idx<raw.length ) {
			if( raw[idx]!=last ) {
				appendLast();
				n = 1;
				last = raw[idx];
			}
			else
				n++;
			idx++;
		}
		appendLast();
		
		return out;
	}
	
	public function uncompressRLE(raw:String) {
		if( raw.length==0 )
			return "";
		
		var out = "";
		var idx = 0;
		while( idx<raw.length ) {
			if( raw.charAt(idx)=="<" ) {
				var end = raw.indexOf(">", idx);
				var expr = raw.substr(idx+1, end-idx-1);
				var n = Std.parseInt( expr.substr(0, expr.indexOf(":")) );
				var c = expr.charAt(expr.length-1);
				for(i in 0...n)
					out+=c;
				idx = end+1;
			}
			else {
				out+=raw.charAt(idx);
				idx++;
			}
		}
		
		return out;
	}
	
		
	// Old XML
	function unserializeXml(data:String) {
		while( Asset.ALL.length>0 )
			Asset.ALL[0].destroy();
			
		initMap();
		
		try {
			
			var xml = new haxe.xml.Fast( Xml.parse(data) );
			var y = 0;
			for(line in xml.node.map.nodes.l) {
				var x = 0;
				for(v in line.innerHTML.split("")) {
					if( isValid(x,y) )
						map[x][y] = v=="1";
					x++;
				}
				y++;
			}
			
			if( xml.hasNode.theme )
				Const.THEME = Const.THEMES.get(xml.node.theme.att.id);
			
			for(a in xml.node.assets.nodes.a)
				Asset.fromXml(a);
		}
		catch(e:Dynamic) {
			man.notify(Tx.ErrLoadingCookie+" ("+e+")");
			initMap();
		}
		
		invalidateBounds();
		redraw();
		man.setTheme(Const.THEME.id);
	}
	
	function isXml(s:String) {
		return s.indexOf("<map>")>=0;
	}
	
	
	
	// Cookies
	public function saveState() {
		var json = serializeJson();
		
		history.push(json);
		while(history.length>100)
			history.shift();
			
		mt.deepnight.Lib.setCookie("rpgMap", "lastName", lastName);
		mt.deepnight.Lib.setCookie("rpgMap", "saveJson", json);
	}
	
	public function loadState() {
		lastName = mt.deepnight.Lib.getCookie("rpgMap", "lastName", "");
		var s = mt.deepnight.Lib.getCookie("rpgMap", "saveJson");
		if( s!=null )
			try {
				if( isXml(s) )
					unserializeXml(s);
				else
					unserializeJson(s);
			}
			catch(e:String) {  man.notify(e); }
			catch(e:Dynamic) {
				man.notify(Tx.ErrLoadingCookie+" ("+e+")");
				initMap();
			}
	}
	
	
	public function load(json:String) {
		initMap();
		unserializeJson(json);
			
		setDraftMode(true);
		saveState();
	}
	
	public function loadData() {
		var file = new flash.net.FileReference();
		file.addEventListener(flash.events.Event.SELECT, function(_) {
			file.load();
		});
		file.addEventListener(flash.events.Event.COMPLETE, function(_) {
			initMap();
			try {
				var s = file.data.toString();
				if( isXml(s) )
					unserializeXml(s);
				else
					unserializeJson(s);
					
				setDraftMode(true);
				man.notify( Tx.Loaded({_file:file.name}) );
				lastName = file.name;
			}
			catch( e:String ) {
				man.notify(e);
			}
			catch( e:Dynamic ) {
				initMap();
				man.notify( Tx.ErrLoading({_file:file.name}) );
			}
			saveState();
		});
		file.browse();
	}
	
	
	public function saveData() {
		var s = serializeJson();
		#if debug
		s = HaxeJson.prettify(s);
		flash.system.System.setClipboard(s);
		#end
		
		saveState();
		
		var file = new flash.net.FileReference();
		file.addEventListener(flash.events.Event.COMPLETE, function(_) {
			lastName = file.name;
			man.notify( Tx.Saved({_file:file.name}) );
			saveState();
		});
		file.save(s, lastName);
	}
	
	
	function getSnapshot() {
		var old = draftMode;
		setDraftMode(false);
		var pt0 = new flash.geom.Point();
		
		var q = man.root.stage.quality;
		man.root.stage.quality = flash.display.StageQuality.HIGH_16X16_LINEAR;

		var bounds = getBounds();
		bounds.x1-=1;
		bounds.y1-=1;
		bounds.x2+=1;
		bounds.y2+=1;
		
		// Base
		showStripes = man.settings.exportStripes;
		grid.visible = man.settings.exportGrid;
		wallTexture.visible = man.settings.exportStripes;
		var bd = new BitmapData((bounds.x2-bounds.x1+1)*Const.GRID, (bounds.y2-bounds.y1+1)*Const.GRID, false, Const.THEME.bg);
		var m = new flash.geom.Matrix();
		m.translate(-bounds.x1*Const.GRID, -bounds.y1*Const.GRID);
		bd.draw(render, m);
		m.translate(-render.x, -render.y);
		
		// Assets
		for(a in Asset.ALL) {
			var m2 = a.sprite.transform.matrix;
			m2.concat(m);
			a.redraw();
			bd.draw(a.sprite, m2);
		}
		
		showStripes = true;
		man.root.stage.quality = q;
		setDraftMode(old);
		wallTexture.visible = true;
		return bd;
	}
	
	
	var printBuffer : flash.display.BitmapData;
	public function print() {
		var printer = new flash.printing.PrintJob();
		printer.addEventListener( flash.events.Event.COMPLETE, function(_) man.notify("Complete") );
		printer.addEventListener( flash.events.Event.CANCEL, function(_) man.notify("Cancel") );
		var options = new flash.printing.PrintJobOptions(true);
		
		var q = man.root.stage.quality;
		man.root.stage.quality = flash.display.StageQuality.HIGH_16X16_LINEAR;
		var bw = man.settings.printBW;

		if( printer.start() ) {
			var pw = printer.pageWidth;
			var ph = printer.pageHeight;

			// Prepare image
			var old = Const.THEME.id;
			if( bw )
				man.setTheme("print");
				
			if( printBuffer!=null )
				printBuffer.dispose();
			printBuffer = getSnapshot();
			var bmp = new Bitmap(printBuffer);
			bmp.smoothing = true;
			var spr = new Sprite();
			man.root.addChild(spr);
			spr.addChild(bmp);
			spr.graphics.beginFill(0xFFFFFF,1);
			spr.graphics.drawRect(0,0,pw,ph);
			
			// Scale
			var bounds = getBounds();
			var sx = Math.min(man.settings.printScale, pw/spr.width);
			var sy = Math.min(man.settings.printScale, ph/spr.height);
			var s = Math.min(sx, sy);
			bmp.scaleX = bmp.scaleY = s;
			
			#if debug
			trace(printBuffer.width+"x"+printBuffer.height);
			trace('page=$pw,$ph');
			trace('s=$sx, $sy, $s');
			trace("bmp="+bmp.width+"x"+bmp.height);
			#end

			// Centering
			var mx = Std.int(pw*0.5 - bmp.width*0.5);
			var my = Std.int(ph*0.5 - bmp.height*0.5);
			bmp.x = mx;
			bmp.y = my;
			
			man.notify("Printing in progress...");
			printer.addPage(spr, options);
			printer.send();
			
			// Clean up
			if( bw )
				man.setTheme(old);
				
			haxe.Timer.delay(function() {
				spr.parent.removeChild(spr);
			}, 3000); // Odd printer bug
			spr.visible = false;
		}
		else
			man.notify("Print error");
			
		man.root.stage.quality = q;
	}
	
	
	public function savePNG() {
		// Render
		var bd = getSnapshot();
		
		// Generate PNG data
		var raw = bd.getPixels(bd.rect);
		var bytes = haxe.io.Bytes.ofData(raw);
		var png = format.png.Tools.build32ARGB(Std.int(bd.width), Std.int(bd.height), bytes); // TODO
		
		var out = new haxe.io.BytesOutput();
		var writer = new format.png.Writer(out);
		writer.write(png);
		
		// Save
		var name = lastName;
		if( name.indexOf(".")>=0 )
			name = name.substr(0, name.lastIndexOf("."));
		name+=".png";
		var file = new flash.net.FileReference();
		file.addEventListener(flash.events.Event.COMPLETE, function(_) {
			man.notify( Tx.ImageSaved({_file:name}) );
		});
		file.save(out.getBytes().getData(), name);
		
		bd.dispose();
	}
	
	public function setGround(cx,cy, g:Bool) {
		if( isValid(cx,cy) )
			map[cx][cy] = !g;
	}
	public function getGround(cx,cy, g:Bool) {
		return if( isValid(cx,cy) )
			map[cx][cy] = !g;
	}
	
	public function pan(dx,dy) {
		var bounds = getBounds();
		var oldMap = map.copy();
		for(x in 0...wid)
			oldMap[x] = map[x].copy();
		
		for(x in 0...wid)
			for(y in 0...hei)
				if( x+dx>0 && x+dx<wid && y+dy>0 && y+dy<hei )
					map[x][y] = oldMap[x+dx][y+dy];
				else
					map[x][y] = true;
		
		for(a in Asset.ALL) {
			a.cx-=dx;
			a.cy-=dy;
		}
		lastBounds.x1-=dx;
		lastBounds.y1-=dy;
		lastBounds.x2-=dx;
		lastBounds.y2-=dy;
		redraw();
	}
	
	public inline function invalidateBounds() {
		lastBounds = null;
	}
	
	public function getBounds() {
		if( lastBounds!=null )
			return {x1:lastBounds.x1, y1:lastBounds.y1, x2:lastBounds.x2, y2:lastBounds.y2};
		
		var b = {x1:wid, y1:hei, x2:0, y2:0};
		for(x in 0...wid)
			for(y in 0...hei) {
				var a = man.getAssetAt(x,y);
				if( isGround(x,y) || a!=null ) {
					if( x<b.x1 ) b.x1 = x;
					if( y<b.y1 ) b.y1 = y;
					if( x>b.x2 ) b.x2 = x;
					if( y>b.y2 ) b.y2 = y;
				}
			}
		
		lastBounds = {x1:b.x1, y1:b.y1, x2:b.x2, y2:b.y2}
		return b;
	}
		
	public function setDraftMode(b:Bool) {
		draftMode = b;
		grid.visible = b;
		//ground.alpha = b ? 0.7 : 1;
		man.draftBt.setSelected(b);
		for(a in Asset.ALL) {
			a.draftMode = b;
			a.redraw();
		}
	}

	
	public function cancel() {
		if( history.length==1 )
			man.notify(Tx.CannotCancel);
		else {
			history.pop();
			var json = history[history.length-1];
			initMap();
			unserializeJson(json);
			man.notify(Tx.Canceled);
		}
		
	}
	
	
	public inline function isGround(cx,cy) {
		if( isValid(cx,cy) )
			return !map[cx][cy];
		else
			return false;
	}
	
	public function redraw() {
		ground.removeChildren();
		
		var m = Math.ceil(Const.GRID*0.2);
		for(x in 0...wid)
			for(y in 0...hei)
				if( isGround(x,y) ) {
					var s = new Sprite();
					ground.addChild(s);
					s.graphics.beginFill(Const.THEME.bg, 1);
					s.graphics.drawRect(-m,-m, Const.GRID+m*2, Const.GRID+m*2);
					s.x = x*Const.GRID;
					s.y = y*Const.GRID;
					s.mouseChildren = s.mouseEnabled = false;
				}
	}
	
	public function update() {
		for(a in Asset.ALL)
			a.update();
	}
}