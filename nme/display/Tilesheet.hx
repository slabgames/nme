package nme.display;


import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.Loader;


class Tilesheet
{
	
	public static inline var TILE_SCALE = 0x0001;
	public static inline var TILE_ROTATION = 0x0002;
	public static inline var TILE_RGB = 0x0004;
	public static inline var TILE_ALPHA = 0x0008;
	
	/**
	 * @private
	 */
	public var nmeBitmap:BitmapData;
	
	#if (cpp || neko)
	
	/**
	 * @private
	 */
	public var nmeHandle:Dynamic;
	
	#else
	
	private var bitmapHeight:Int;
	private var bitmapWidth:Int;
	private var tilePoints:Array<Point>;
	private var tiles:Array<Rectangle>;
	private var tileUVs:Array<Rectangle>;

	#end
	
	
	public function new(inImage:BitmapData)
	{
		nmeBitmap = inImage;
		
		#if (cpp || neko)
		
		nmeHandle = nme_tilesheet_create(inImage.nmeHandle);
		
		#else
		
		bitmapWidth = nmeBitmap.width;
		bitmapHeight = nmeBitmap.height;
		
		tilePoints = new Array<Point>();
		tiles = new Array<Rectangle>();
		tileUVs = new Array<Rectangle>();
		
		#end
	}
	
	
	public function addTileRect(rectangle:Rectangle, centerPoint:Point = null)
	{
		#if (cpp || neko)
		
		nme_tilesheet_add_rect(nmeHandle, rectangle, centerPoint);
		
		#else
		
		tiles.push(rectangle);
		tilePoints.push(centerPoint);
		tileUVs.push(new Rectangle(rectangle.left / bitmapWidth, rectangle.top / bitmapHeight, rectangle.right / bitmapWidth, rectangle.bottom / bitmapHeight));
		
		#end
	}
	
	
	/**
	 * Fast method to draw a batch of tiles using a Tilesheet
	 * 
	 * The input array accepts the x, y and tile ID for each tile you wish to draw.
	 * For example, an array of [ 0, 0, 0, 10, 10, 1 ] would draw tile 0 to (0, 0) and
	 * tile 1 to (10, 10)
	 * 
	 * You can also set flags for TILE_SCALE, TILE_ROTATION, TILE_RGB and
	 * TILE_ALPHA.
	 * 
	 * Depending on which flags are active, this is the full order of the array:
	 * 
	 * [ x, y, tile ID, scale, rotation, red, green, blue, alpha, x, y ... ]
	 * 
	 * @param	graphics		The nme.display.Graphics object to use for drawing
	 * @param	tileData		An array of all position, ID and optional values for use in drawing
	 * @param	smooth		(Optional) Whether drawn tiles should be smoothed (Default: false)
	 * @param	flags		(Optional) Flags to enable scale, rotation, RGB and/or alpha when drawing (Default: 0)
	 */
	public function drawTiles (graphics:Graphics, tileData:Array<Float>, smooth:Bool = false, flags:Int = 0):Void
	{
		#if (cpp || neko)
		
		graphics.drawTiles (this, tileData, smooth, flags);
		
		#else
		
		var useScale = (flags & TILE_SCALE) > 0;
		var useRotation = (flags & TILE_ROTATION) > 0;
		var useRGB = (flags & TILE_RGB) > 0;
		var useAlpha = (flags & TILE_ALPHA) > 0;
		
		var scaleIndex = 0;
		var rotationIndex = 0;
		var rgbIndex = 0;
		var alphaIndex = 0;
		var numValues = 3;
		
		if (useScale)
		{
			scaleIndex = numValues;
			numValues ++;
		}
		
		if (useRotation)
		{
			rotationIndex = numValues;
			numValues ++;
		}
		
		if (useRGB)
		{
			rgbIndex = numValues;
			numValues += 3;
		}
		
		if (useAlpha)
		{
			alphaIndex = numValues;
			numValues ++;
		}
		
		var totalCount = tileData.length;
		var itemCount = Std.int (totalCount / numValues);
		
		var vertices = new Vector<Float> (itemCount * 8, true);
		var indices = new Vector<Int> (itemCount * 6, true);
		var uvtData = new Vector<Float> (itemCount * 8, true);
		
		var offset4 = 0;
		var offset6 = 0;
		var offset8 = 0;
		
		var index = 0;
		var tileID:Int = 0;
		var cacheID:Int = -1;
		
		var tile:Rectangle = null;
		var tileUV:Rectangle = null;
		var tilePoint:Point = null;
		
		while (index < totalCount)
		{
			var x = tileData[index];
			var y = tileData[index + 1];
			var tileID = Std.int(tileData[index + 2]);
			
			if (cacheID != tileID)
			{
				cacheID = tileID;
				tile = tiles[tileID];
				tileUV = tileUVs[tileID];
				tilePoint = tilePoints[tileID];
			}
			
			var scale = 1.0;
			var rotation = 0.0;
			var alpha = 1.0;
			
			if (useScale)
			{
				scale = tileData[index + scaleIndex];
			}
			
			if (useRotation)
			{
				rotation = tileData[index + rotationIndex];
			}
			
			if (useRGB)
			{
				//ignore for now
			}
			
			if (useAlpha)
			{
				alpha = tileData[index + alphaIndex];
			}
			
			if (tilePoint != null)
			{
				x -= tilePoint.x;
				y -= tilePoint.y;
			}
			
			vertices[offset8] = vertices[offset8 + 4] = x;
			vertices[offset8 + 1] = vertices[offset8 + 3] = y;
			vertices[offset8 + 2] = vertices[offset8 + 6] = x + (tile.width * scale);
			vertices[offset8 + 5] = vertices[offset8 + 7] = y + (tile.height * scale);
			
			indices[offset6] = 0 + offset4;
			indices[offset6 + 1] = indices[offset6 + 3] = 1 + offset4;
			indices[offset6 + 2] = indices[offset6 + 5] = 2 + offset4;
			indices[offset6 + 4] = 3 + offset4;
			
			uvtData[offset8] = uvtData[offset8 + 4] = tileUV.left;
			uvtData[offset8 + 1] = uvtData[offset8 + 3] = tileUV.top;
			uvtData[offset8 + 2] = uvtData[offset8 + 6] = tileUV.right;
			uvtData[offset8 + 5] = uvtData[offset8 + 7] = tileUV.bottom;
			
			offset4 += 4;
			offset6 += 6;
			offset8 += 8;
			
			index += numValues;
		}
		
		graphics.beginBitmapFill (nmeBitmap, null, false, smooth);
		graphics.drawTriangles (vertices, indices, uvtData);
		graphics.endFill ();
		
		/*var index = 0;
		var matrix = new Matrix ();
		
		while (index < tileData.length)
		{
			var x = tileData[index];
			var y = tileData[index + 1];
			var tileID = Std.int (tileData[index + 2]);
			index += 3;
			
			var tile = tiles[tileID];
			//var centerPoint = tilePoints[tileID];
			
			var scale = 1.0;
			var rotation = 0.0;
			var alpha = 1.0;
			
			if (useScale)
			{
				scale = tileData[index];
				index ++;
			}
			
			if (useRotation)
			{
				rotation = tileData[index];
				index ++;
			}
			
			if (useRGB)
			{
				//ignore for now
				index += 3;
			}
			
			if (useAlpha)
			{
				alpha = tileData[index];
				index++;
			}
			
			matrix.tx = x - tile.x;
			matrix.ty = y - tile.y;
			
			// need to add support for rotation, alpha, scale and RGB
			
			graphics.beginBitmapFill (nmeBitmap, matrix, false, smooth);
			graphics.drawRect (x, y, tile.width, tile.height);
		}
		
		graphics.endFill ();*/
		
		#end
	}
	
	
	
	// Native Methods
	
	
	
	#if (cpp || neko)
	
	private static var nme_tilesheet_create = Loader.load("nme_tilesheet_create", 1);
	private static var nme_tilesheet_add_rect = Loader.load("nme_tilesheet_add_rect", 3);
	
	#end
	
}