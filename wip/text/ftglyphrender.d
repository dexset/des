module des.text.ftglyphrender;

public import des.text.textrender;
import des.math.linear;

import derelict.freetype.ft;
import derelict.freetype.types;

class FTGlyphRenderException: Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

class FTGlyphRender : GlyphRender
{
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

    auto color = col4( 1,1,1,1 );
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
        color = p.color;
    }

    @property ElemInfo imtype() const { return ElemInfo( DataType.UBYTE, 4 ); }

    GlyphInfo render( wchar ch )
    {
        if( FT_Load_Char( face, cast(size_t)ch, FT_LOAD_RENDER ) )
            throw new FTGlyphRenderException( "Couldn't load char" );

        auto g = face.glyph;
        ivec2 sz = ivec2( g.bitmap.width, g.bitmap.rows );

        auto ret = GlyphInfo( ivec2( g.bitmap_left, -g.bitmap_top ), 
                                ivec2( cast(int)( g.advance.x >> 6 ), 
                                       cast(int)( g.advance.y >> 6 ) ),
                                Image!2( imsize_t(sz), imtype ) );

        foreach( y; 0 .. sz.y )
            foreach( x; 0 .. sz.x )
                ret.img.pixel!ubcol4(x,y) = ubcol4( col4( color.rgb, color.a * g.bitmap.buffer[y*sz.x+x] / 255.0 ) * 255 );

        return ret;
    }

    void destroy()
    { 
        if( FT_Done_Face !is null )
            FT_Done_Face( face ); 
    }

    static ~this() 
    { 
        if( lib_inited && FT_Done_FreeType !is null ) 
            FT_Done_FreeType( ft ); 
    }
}

