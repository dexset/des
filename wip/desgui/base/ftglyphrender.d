/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

module desgui.base.ftglyphrender;

public import desgui.core.textrender;
import desmath.linear.vector;
import desil;

import derelict.freetype.ft;
import derelict.freetype.types;

import desutil.logger;
mixin( PrivateLoggerMixin );

class FTGlyphRenderException: Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

class FTGlyphRender : DiGlyphRender
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
            log_error( "font load attempt: %d", i );
        }

        if( loaderror )
            throw new FTGlyphRenderException( "Couldn't open font '" ~ fontname ~ "': loading error" );

        if( FT_Select_Charmap( face, FT_Encoding.FT_ENCODING_UNICODE ) )
            throw new FTGlyphRenderException( "Couldn't select unicode encoding" );
    }

    auto color = col4( 1,1,1,1 );
public:

    static DiGlyphRender get( string fontname )
    {
        if( fontname !in openFTGR )
            openFTGR[fontname] = new FTGlyphRender( fontname );
        return openFTGR[fontname];
    }

    void setParams( in DiGlyphParam p )
    {
        FT_Set_Pixel_Sizes( face, 0, p.height );
        color = p.color;
    }

    @property ImageType imtype() const { return ImageType( ImCompType.UBYTE, 4 ); }

    DiGlyphInfo render( wchar ch )
    {
        if( FT_Load_Char( face, cast(size_t)ch, FT_LOAD_RENDER ) )
            throw new FTGlyphRenderException( "Couldn't load char" );

        auto g = face.glyph;
        ivec2 sz = ivec2( g.bitmap.width, g.bitmap.rows );

        alias vec!(4,ubyte,"rgba") bcol4;

        auto ret = DiGlyphInfo( ivec2( g.bitmap_left, -g.bitmap_top ), 
                                ivec2( cast(int)( g.advance.x >> 6 ), 
                                       cast(int)( g.advance.y >> 6 ) ),
                                Image( imsize_t(sz), imtype ) );

        foreach( y; 0 .. sz.y )
            foreach( x; 0 .. sz.x )
                ret.img.access!bcol4(x,y) = bcol4( col4( color.rgb, color.a * g.bitmap.buffer[y*sz.x+x] / 255.0 ) * 255 );

        return ret;
    }

    ~this() 
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
