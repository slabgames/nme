package nme.script;
import nme.utils.ByteArray;

using StringTools;

class Nme
{
   static function inflate(data:haxe.io.Bytes)
   {
       var result = new ByteArray();

       var bufSize = 65536;
       var tmp = haxe.io.Bytes.alloc(bufSize);
       var z = new haxe.zip.InflateImpl(new haxe.io.BytesInput(data), false, false);
       while( true ) {
         var n = z.readBytes(tmp, 0, bufSize);
         result.writeHaxeBytes(tmp, 0, n);
         if( n < bufSize )
            break;
         }
       return result;
   }


   public static function runInput(input:haxe.io.BytesInput)
   {
      var zip = new haxe.zip.Reader( input );
      var entries = zip.read();
      var script:String = null;
      for(entry in entries)
      {
         if (entry.fileName=="ScriptMain.cppia")
         {
            var data = entry.data;
            if (entry.compressed)
            {
               var byteArray = inflate(data);
               script = byteArray.getString(0,byteArray.length);
            }
            else
               script = data.getString(0,data.length);
         }
         else if (entry.fileName.startsWith("assets/"))
         {
            nme.Assets.byteFactory.set(entry.fileName.substr(7), function() return inflate(entry.data)  );
         }
         else
         {
            // Ignore this entry?
         }
      }
      #if (cpp && !cppia)
      if (script==null)
         throw "Could not find script in input";
      cpp.cppia.Host.run(script);
      #else
      throw "Script not available on this platform";
      #end
   }

   public static function runFile(inFilename:String)
   {
      #if (cpp && !cppia)
      if (inFilename.endsWith(".nme"))
      {
         var bytes = sys.io.File.getBytes(inFilename);
         runInput( new haxe.io.BytesInput(bytes) );
      }
      else
      {
         var contents = sys.io.File.getContent(inFilename);
         cpp.cppia.Host.run(contents);
      }
      #else
      throw "Script not available on this platform";
      #end
   }

   public static function runResource(?inResource:String)
   {
      #if (cpp && !cppia)
      if (inResource==null)
          inResource = "ScriptMain.cppia";
      var script = nme.Assets.getString(inResource);
      if (script==null)
         throw "Could not find resource script " + inResource;
      cpp.cppia.Host.run(script);
      #else
      throw "Script not available on this platform";
      #end
   }
}


