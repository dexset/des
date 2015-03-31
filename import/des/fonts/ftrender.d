module des.fonts.ftrender;

import des.math.linear;
import des.il;
import des.util.logsys;
import des.util.arch.emm;
import des.util.stdext;

import derelict.freetype.ft;
import derelict.freetype.types;

import std.traits;

import des.fonts.base;

///
class FTException : FontException
{
    ///
    FTError code;
    ///
    this( string msg, FTError code, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    {
        this.code = code;
        super( msg, file, line );
    }
}

void checkFTCall(alias fnc, string info="", string file=__FILE__, size_t line=__LINE__,Args...)( Args args )
{
    auto err = cast(FTError)fnc(args);
    auto fmtInfo = info ? ( format( " (%s)", info ) ) : "";
    if( err != FTError.NONE )
        throw new FTException( format( "'%s'%s fails: %s", fnc.stringof, fmtInfo, err ), err );
}

class FTFontRender : FontRender, ExternalMemoryManager
{
    mixin EMM;

protected:

    void selfDestroy()
    { 
        if( FT_Done_Face !is null )
            FT_Done_Face( face ); 
    }

private:

    static lib_inited = false;

    static FT_Library ft;

    static FTFontRender[string] openRender;

    static this()
    {
        if( !lib_inited )
        {
            DerelictFT.load();
            checkFTCall!FT_Init_FreeType( &ft );
            lib_inited = true;
        }
    }

    static ~this() 
    { 
        if( lib_inited && FT_Done_FreeType !is null ) 
            checkFTCall!FT_Done_FreeType( ft ); 
    }

protected:

    this( string fontname )
    {
        import std.file;

        if( !fontname.exists )
            throw new FontException( "Couldn't open font '" ~ fontname ~ "': file not exist" );

        checkFTCall!FT_New_Face( ft, fontname.toStringz, 0, &face );

        checkFTCall!(FT_Select_Charmap,"unicode")( face, FT_ENCODING_UNICODE );
    }

    FT_Face face;

    FontRenderParam param;

    static immutable ElemInfo imtype = ElemInfo( 1, DataType.UBYTE );

public:

    static FontRender get( string fontname )
    {
        if( fontname !in openRender )
            openRender[fontname] = new FTFontRender( fontname );
        return openRender[fontname];
    }

    void setParams( in FontRenderParam p ) { param = p; }

    GlyphImage renderChar( wchar ch )
    {
        checkFTCall!FT_Load_Char( face, cast(ulong)ch, FT_LOAD_RENDER );

        auto g = face.glyph;

        ivec2 sz;
        ubyte[] img_data;

        if( ch == ' ' )
        {
            auto width = g.metrics.horiAdvance >> 6;
            sz = ivec2( width, g.bitmap.rows );
            img_data.length = sz.x * sz.y;
        }
        else
        {
            sz = ivec2( g.bitmap.width, g.bitmap.rows );
            img_data = g.bitmap.buffer[0 .. sz.x*sz.y].dup;
        }

        return GlyphImage(
                   Glyph( ""w ~ ch,
                       ivec2( g.bitmap_left, -g.bitmap_top ),
                       ivec2( g.advance.x >> 6, g.advance.y >> 6 ),
                       sz
                   ),
                   Image.external( sz, imtype, img_data )
               );
    }

    BitmapFont generateBitmapFont( wstring chars )
    {
        checkFTCall!FT_Set_Pixel_Sizes( face, 0, param.height );

        logger.Debug( param.height );

        BitmapFont res;
        res.height = param.height;

        GlyphImage[wchar] glyphs;

        foreach( c; chars ) glyphs[c] = renderChar(c);

        uint maxh = 0;
        uint width = 0;

        foreach( gi; glyphs )
        {
            if( gi.image.size[1] > maxh )
                maxh = cast(uint)(gi.image.size[1]);
            width += gi.image.size[0];
        }

        res.image = Image( ivec2(width,maxh), imtype );

        auto offset = ivec2(0);

        foreach( key, gi; glyphs )
        {
            res.info[key] = BitmapGlyph( gi.glyph, offset );
            imCopy( res.image, offset, gi.image );
            offset += ivec2( gi.image.size[0], 0 );
        }

        return res;
    }
}

///
enum FTError
{
    NONE                          = 0x00, /// no error

    CANNOT_OPEN_RESOURCE          = 0x01, /// cannot open resource
    UNKNOWN_FILE_FORMAT           = 0x02, /// unknown file format
    INVALID_FILE_FORMAT           = 0x03, /// broken file
    INVALID_VERSION               = 0x04, /// invalid FreeType version
    LOWER_MODULE_VERSION          = 0x05, /// module version is too low
    INVALID_ARGUMENT              = 0x06, /// invalid argument
    UNIMPLEMENTED_FEATURE         = 0x07, /// unimplemented feature
    INVALID_TABLE                 = 0x08, /// broken table
    INVALID_OFFSET                = 0x09, /// broken offset within table
    ARRAY_TOO_LARGE               = 0x0A, /// array allocation size too large

    /* GLYPH/CHARACTER ERRORS */

    INVALID_GLYPH_INDEX           = 0x10, /// invalid glyph index
    INVALID_CHARACTER_CODE        = 0x11, /// invalid character code
    INVALID_GLYPH_FORMAT          = 0x12, /// unsupported glyph image format
    CANNOT_RENDER_GLYPH           = 0x13, /// cannot render this glyph format
    INVALID_OUTLINE               = 0x14, /// invalid outline
    INVALID_COMPOSITE             = 0x15, /// invalid composite glyph
    TOO_MANY_HINTS                = 0x16, /// too many hints
    INVALID_PIXEL_SIZE            = 0x17, /// invalid pixel size

    /* HANDLE ERRORS */

    INVALID_HANDLE                = 0x20, /// invalid object handle
    INVALID_LIBRARY_HANDLE        = 0x21, /// invalid library handle
    INVALID_DRIVER_HANDLE         = 0x22, /// invalid module handle
    INVALID_FACE_HANDLE           = 0x23, /// invalid face handle
    INVALID_SIZE_HANDLE           = 0x24, /// invalid size handle
    INVALID_SLOT_HANDLE           = 0x25, /// invalid glyph slot handle
    INVALID_CHARMAP_HANDLE        = 0x26, /// invalid charmap handle
    INVALID_CACHE_HANDLE          = 0x27, /// invalid cache manager handle
    INVALID_STREAM_HANDLE         = 0x28, /// invalid stream handle

    /* DRIVER ERRORS */

    TOO_MANY_DRIVERS              = 0x30, /// too many modules
    TOO_MANY_EXTENSIONS           = 0x31, /// too many extensions

    /* MEMORY ERRORS */

    OUT_OF_MEMORY                 = 0x40, /// out of memory
    UNLISTED_OBJECT               = 0x41, /// unlisted object

    /* STREAM ERRORS */

    CANNOT_OPEN_STREAM            = 0x51, /// cannot open stream
    INVALID_STREAM_SEEK           = 0x52, /// invalid stream seek
    INVALID_STREAM_SKIP           = 0x53, /// invalid stream skip
    INVALID_STREAM_READ           = 0x54, /// invalid stream read
    INVALID_STREAM_OPERATION      = 0x55, /// invalid stream operation
    INVALID_FRAME_OPERATION       = 0x56, /// invalid frame operation
    NESTED_FRAME_ACCESS           = 0x57, /// nested frame access
    INVALID_FRAME_READ            = 0x58, /// invalid frame read

    /* RASTER ERRORS */

    RASTER_UNINITIALIZED          = 0x60, /// raster uninitialized
    RASTER_CORRUPTED              = 0x61, /// raster corrupted
    RASTER_OVERFLOW               = 0x62, /// raster overflow
    RASTER_NEGATIVE_HEIGHT        = 0x63, /// negative height while rastering

    /* CACHE ERRORS */

    TOO_MANY_CACHES               = 0x70, /// too many registered caches

    /* TRUETYPE AND SFNT ERRORS */

    INVALID_OPCODE                = 0x80, /// invalid opcode
    TOO_FEW_ARGUMENTS             = 0x81, /// too few arguments
    STACK_OVERFLOW                = 0x82, /// stack overflow
    CODE_OVERFLOW                 = 0x83, /// code overflow
    BAD_ARGUMENT                  = 0x84, /// bad argument
    DIVIDE_BY_ZERO                = 0x85, /// division by zero
    INVALID_REFERENCE             = 0x86, /// invalid reference
    DEBUG_OPCODE                  = 0x87, /// found debug opcode
    ENDF_IN_EXEC_STREAM           = 0x88, /// found ENDF opcode in execution stream
    NESTED_DEFS                   = 0x89, /// nested DEFS
    INVALID_CODERANGE             = 0x8A, /// invalid code range
    EXECUTION_TOO_LONG            = 0x8B, /// execution context too long
    TOO_MANY_FUNCTION_DEFS        = 0x8C, /// too many function definitions
    TOO_MANY_INSTRUCTION_DEFS     = 0x8D, /// too many instruction definitions
    TABLE_MISSING                 = 0x8E, /// SFNT font table missing
    HORIZ_HEADER_MISSING          = 0x8F, /// horizontal header (hhea) table missing
    LOCATIONS_MISSING             = 0x90, /// locations (loca) table missing
    NAME_TABLE_MISSING            = 0x91, /// name table missing
    CMAP_TABLE_MISSING            = 0x92, /// character map (cmap) table missing
    HMTX_TABLE_MISSING            = 0x93, /// horizontal metrics (hmtx) table missing
    POST_TABLE_MISSING            = 0x94, /// PostScript (post) table missing
    INVALID_HORIZ_METRICS         = 0x95, /// invalid horizontal metrics
    INVALID_CHARMAP_FORMAT        = 0x96, /// invalid character map (cmap) format
    INVALID_PPEM                  = 0x97, /// invalid ppem value
    INVALID_VERT_METRICS          = 0x98, /// invalid vertical metrics
    COULD_NOT_FIND_CONTEXT        = 0x99, /// could not find context
    INVALID_POST_TABLE_FORMAT     = 0x9A, /// invalid PostScript (post) table format
    INVALID_POST_TABLE            = 0x9B, /// invalid PostScript (post) table

    /* CFF, CID, AND TYPE 1 ERRORS */

    SYNTAX_ERROR                  = 0xA0, /// opcode syntax error
    STACK_UNDERFLOW               = 0xA1, /// argument stack underflow
    IGNORE                        = 0xA2, /// ignore
    NO_UNICODE_GLYPH_NAME         = 0xA3, /// no Unicode glyph name found


    /* BDF ERRORS */

    MISSING_STARTFONT_FIELD       = 0xB0, /// `STARTFONT' field missing
    MISSING_FONT_FIELD            = 0xB1, /// `FONT' field missing
    MISSING_SIZE_FIELD            = 0xB2, /// `SIZE' field missing
    MISSING_FONTBOUNDINGBOX_FIELD = 0xB3, /// `FONTBOUNDINGBOX' field missing
    MISSING_CHARS_FIELD           = 0xB4, /// `CHARS' field missing
    MISSING_STARTCHAR_FIELD       = 0xB5, /// `STARTCHAR' field missing
    MISSING_ENCODING_FIELD        = 0xB6, /// `ENCODING' field missing
    MISSING_BBX_FIELD             = 0xB7, /// `BBX' field missing
    BBX_TOO_BIG                   = 0xB8, /// `BBX' too big
    CORRUPTED_FONT_HEADER         = 0xB9, /// Font header corrupted or missing fields
    CORRUPTED_FONT_GLYPHS         = 0xBA, /// Font glyphs corrupted or missing fields
}
