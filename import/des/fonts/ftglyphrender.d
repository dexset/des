module des.fonts.ftglyphrender;

import des.math.linear;
import des.il;
import des.util.arch.emm;
import des.util.stdext;

import derelict.freetype.ft;
import derelict.freetype.types;

import std.traits;

alias CrdVector!2 imsize_t;

struct BitmapChar
{
    /// offset in image coords
    ivec2 offset;

    /// position in offset coords
    ivec2 pos;

    /// size of glyph in image
    ivec2 size;

    /// next glyph position for drawing
    ivec2 next;
}

struct BitmapFont
{
    BitmapChar[wchar] info;
    Image!2 texture;
}

class FTGlyphRenderException: Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

struct GlyphInfo
{
    ivec2 pos, next;
    @property ivec2 size() const { return ivec2( img.size ); }
    Image!2 img;
}

struct GlyphParam
{
    enum Flag
    {
        NONE        = cast(ubyte)0,
        BOLD        = 0b0001,
        ITALIC      = 0b0010,
        UNDERLINE   = 0b0100,
        STRIKED     = 0b1000
    }

    ubyte flag = Flag.NONE;
    uint height=12;
}

interface GlyphRender
{
    void setParams( in GlyphParam p );
    @property ElemInfo imtype() const;
    GlyphInfo render( wchar ch );
    BitmapFont generateBitmapFont( wstring );
}

class FTGlyphRender : GlyphRender, ExternalMemoryManager
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

    static FTGlyphRender[string] openFTGR;

    FT_Face face;

    static this()
    {
        if( !lib_inited )
        {
            DerelictFT.load();
            if( FT_Init_FreeType( &ft ) )
                throw new FTGlyphRenderException( "Couldn't init freetype library" );

            lib_inited = true;
        }
    }

    this( string fontname )
    {
        import std.file;
        if( !fontname.exists )
            throw new FTGlyphRenderException( "Couldn't open font '" ~ fontname ~ "': file not exist" );

        bool loaderror = false;
        foreach( i; 0 .. 100 )
        {
            if( FT_New_Face( ft, fontname.dup.ptr, 0, &face ) ) loaderror = true;
            else { loaderror = false; break; }
        }

        if( loaderror )
            throw new FTGlyphRenderException( "Couldn't open font '" ~ fontname ~ "': loading error" );

        if( FT_Select_Charmap( face, FT_ENCODING_UNICODE ) )
            throw new FTGlyphRenderException( "Couldn't select unicode encoding" );
    }

public:

    static GlyphRender get( string fontname )
    {
        if( fontname !in openFTGR )
            openFTGR[fontname] = new FTGlyphRender( fontname );
        return openFTGR[fontname];
    }

    void setParams( in GlyphParam p )
    {
        FT_Set_Pixel_Sizes( face, 0, p.height );
    }

    @property ElemInfo imtype() const { return ElemInfo( DataType.FLOAT, 1 ); }

    GlyphInfo render( wchar ch )
    {
        if( FT_Load_Char( face, cast(size_t)ch, FT_LOAD_RENDER ) )
            throw new FTGlyphRenderException( "Couldn't load char" );

        auto g = face.glyph;

        ivec2 sz;
        float[] img_data;

        if( ch == ' ' )
        {
            auto width = g.metrics.horiAdvance / 128.0;//TODO not proper way I think
            sz = ivec2( width, g.bitmap.rows );
            img_data.length = sz.x * sz.y;
            img_data[] = 0;
        }
        else
        {
            sz = ivec2( g.bitmap.width, g.bitmap.rows );
            img_data = amap!(a => a / 255.0f)(g.bitmap.buffer[0 .. sz.x * sz.y]);
        }

        return GlyphInfo( ivec2( g.bitmap_left, -g.bitmap_top ), 
                                ivec2( cast(int)( g.advance.x >> 6 ), 
                                       cast(int)( g.advance.y >> 6 ) ),
                                Image!2( imsize_t(sz), imtype, img_data ) );
    }

    BitmapFont generateBitmapFont( wstring chars )
    {
        BitmapFont res;

        GlyphInfo[wchar] glyphs;

        foreach( c; chars ) glyphs[c] = render( c );

        uint maxh = 0;
        uint width = 0;

        foreach( ref g; glyphs )
        {
            if( g.img.size.h > maxh )
                maxh = cast( uint )g.img.size.h;
            width += g.img.size.w;
        }

        res.texture = Image!2( imsize_t( width, maxh ), imtype );

        auto offset = ivec2(0);

        foreach( key, g; glyphs )
        {
            res.info[key] = convGlyphInfoToBitmapChar( g, offset );
            imPaste( res.texture, offset, g.img );
            offset += ivec2( g.img.size.w, 0 );
        }
        return res;
    }

    static ~this() 
    { 
        if( lib_inited && FT_Done_FreeType !is null ) 
            FT_Done_FreeType( ft ); 
    }

protected:

    BitmapChar convGlyphInfoToBitmapChar( in GlyphInfo g, ivec2 offset )
    { return BitmapChar( offset, g.pos, g.size, g.next ); }
}
