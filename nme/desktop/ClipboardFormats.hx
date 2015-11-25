package nme.desktop;

#if (cpp || neko)
enum ClipboardFormats {
	AIR_PREFIX;
	BITMAP_FORMAT;
	FILE_LIST_FORMAT;
	FILE_PROMISE_LIST_FORMAT;
	FLASH_PREFIX;
	HTML_FORMAT;
	REFERENCE_PREFIX;
	RICH_TEXT_FORMAT;
	SERIALIZATION_PREFIX;
	TEXT_FORMAT;
	URL_FORMAT;
}
#else
typedef ClipboardTransferMode = flash.desktop.ClipboardFormats;
#end
