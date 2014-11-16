module des.text.textrender;

public import des.math.linear;
public import des.il;

import std.string;

alias Image!(2).imsize_t imsize_t;

class TextRenderException: Exception
{ 
    @safe nothrow pure this( string msg, string file=__FILE__, size_t line=__LINE__ )
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
    col4 color=col4(1,1,1,1);
}

interface GlyphRender
{
    void setParams( in GlyphParam p );
    @property PixelType imtype() const;
    GlyphInfo render( wchar ch );
}

interface TextRender
{
    GlyphInfo opCall( GlyphRender gr, in GlyphParam gp, wstring str );
}

class BaseLineTextRender: TextRender
{
protected:
    final GlyphInfo renderLine( GlyphRender gr, in GlyphParam param, wstring str )
    {
        GlyphInfo res;
        res.img = Image!2( imsize_t(1,1), gr.imtype );
        if( str == "" ) return res;

        gr.setParams( param );
        auto pen = ivec2( 0, 0 );

        GlyphInfo[] buf;

        iRegion2 max;

        {
            auto g = gr.render( str[0] );
            pen += g.next;
            buf ~= g;
            max = iRegion2( g.pos, g.img.size );
        }

        foreach( i, ch; str[1 .. $] )
        {
            auto g = gr.render( ch );
            g.pos += pen;
            pen += g.next;
            buf ~= g;
            max = max.expand( iRegion2( g.pos, g.img.size ) );
        }

        res.img = Image!2( imsize_t(max.size), gr.imtype );

        foreach( g; buf )
        {
            auto pp = g.pos - max.pos;
            res.img.paste( pp, g.img );
            res.next += g.next;
        }
        res.pos = max.pos;

        return res;
    }
public:
    GlyphInfo opCall( GlyphRender gr, in GlyphParam param, wstring str )
    {
        if( gr is null ) 
            throw new TextRenderException( "null glyph render" );
        auto res = renderLine( gr, param, str );

        return res;
    }
}

class MultilineTextRender : BaseLineTextRender
{
private:
    void mwidth( ref imsize_t v1, in imsize_t v2 )
    {
        v1.w = v1.w > v2.w ? v1.w : v2.w;
        v1.h += v2.h + off;
    } 

    uint off;
public:
    override GlyphInfo opCall( GlyphRender gr, in GlyphParam param, wstring str )
    {
        if( gr is null ) 
            throw new TextRenderException( "null glyph render" );
        auto lines = str.split( "\n" );
        GlyphInfo[] glyphs;
        if( glyphs.length == 1 )
            return glyphs[0];
        imsize_t sz;
        foreach( l; lines )
        {
            glyphs ~= renderLine( gr, param, l );
            mwidth( sz, glyphs[$-1].img.size );
        }

        GlyphInfo res;
        res.img = Image!2( imsize_t(sz), gr.imtype );
        uint pos = 0;
        foreach( g; glyphs )
        {
            res.img.paste( ivec2( 0, pos ), g.img );
            pos += g.img.size.h + off;
        }

        return res;
    }

    @property void offset( uint v ) { off = v; }
    @property uint offset() { return off; }
}
