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

module desgui.core.textrender;

public import desmath.linear.vector,
              desil.rect;

public import desil.image;

import desgui.core.except;

import std.string;

class DiTextRenderException: DiException
{ 
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe nothrow pure
    { super( msg, file, line ); } 
}

struct DiGlyphInfo
{
    ivec2 pos, next;
    @property ivec2 size() const { return ivec2( img.size ); }
    Image img;
}

struct DiGlyphParam
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

interface DiGlyphRender
{
    void setParams( in DiGlyphParam p );
    @property ImageType imtype() const;
    DiGlyphInfo render( wchar ch );
}

interface DiTextRender
{
    DiGlyphInfo opCall( DiGlyphRender gr, in DiGlyphParam gp, wstring str );
}

class DiBaseLineTextRender: DiTextRender
{
    DiGlyphInfo opCall( DiGlyphRender gr, in DiGlyphParam param, wstring str )
    {
        if( gr is null ) 
            throw new DiTextRenderException( "null glyph render" );

        DiGlyphInfo res;
        res.img.allocate( imsize_t(1,1), gr.imtype );
        if( str == "" ) return res;

        gr.setParams( param );
        auto pen = ivec2( 0, 0 );

        DiGlyphInfo[] buf;

        irect max;

        {
            auto g = gr.render( str[0] );
            pen += g.next;
            buf ~= g;
            max = irect( g.pos, g.img.size );
        }

        foreach( i, ch; str[1 .. $] )
        {
            auto g = gr.render( ch );
            g.pos += pen;
            pen += g.next;
            buf ~= g;
            max = max.expand( irect( g.pos, g.img.size ) );
        }

        res.img.allocate( imsize_t(max.size), gr.imtype );

        foreach( g; buf )
        {
            auto pp = g.pos - max.pos;
            res.img.paste( pp, g.img );
            res.next += g.next;
        }
        res.pos = max.pos;

        return res;
    }
}

version(unittest)
{
    package
    {
        ubyte[] data_t = 
        [
            0,2,3,4,0,
            0,0,4,0,0,
            0,0,5,0,0,
            0,0,6,0,0,
            0,0,7,0,0
        ];

        ubyte[] data_t_str = 
        [
            0,2,3,4,0,
            0,0,4,0,0,
            8,8,8,8,8,
            0,0,6,0,0,
            0,0,7,0,0
        ];

        ubyte[] data_e = 
        [
            0,1,2,3,0,
            0,2,0,0,0,
            0,3,4,5,0,
            0,4,0,0,0,
            0,5,6,7,0
        ];


        ubyte[] data_e_str = 
        [
            0,1,2,3,0,
            0,2,0,0,0,
            8,8,8,8,8,
            0,4,0,0,0,
            0,5,6,7,0
        ];

        ubyte[] data_s = 
        [
            0,0,2,1,0,
            0,3,0,0,0,
            0,4,5,6,0,
            0,0,0,7,0,
            0,9,8,0,0
        ];

        ubyte[] data_s_str = 
        [
            0,0,2,1,0,
            0,3,0,0,0,
            8,8,8,8,8,
            0,0,0,7,0,
            0,9,8,0,0
        ];

        ubyte[] data_test_test =
        [
            0,2,3,4,0,0,0,1,2,3,0,0,0,0,2,1,0,0,0,2,3,4,0,0,0,0,0,0,0,2,3,4,0,0,0,1,2,3,0,0,0,0,2,1,0,0,0,2,3,4,0,
            0,0,4,0,0,0,0,2,0,0,0,0,0,3,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,4,0,0,0,0,2,0,0,0,0,0,3,0,0,0,0,0,0,4,0,0,
            0,0,5,0,0,0,0,3,4,5,0,0,0,4,5,6,0,0,0,0,5,0,0,0,0,0,0,0,0,0,5,0,0,0,0,3,4,5,0,0,0,4,5,6,0,0,0,0,5,0,0,
            0,0,6,0,0,0,0,4,0,0,0,0,0,0,0,7,0,0,0,0,6,0,0,0,0,0,0,0,0,0,6,0,0,0,0,4,0,0,0,0,0,0,0,7,0,0,0,0,6,0,0,
            0,0,7,0,0,0,0,5,6,7,0,0,0,9,8,0,0,0,0,0,7,0,0,0,0,0,0,0,0,0,7,0,0,0,0,5,6,7,0,0,0,9,8,0,0,0,0,0,7,0,0
        ];


        ubyte[] data_test_test_str =
        [
            0,2,3,4,0,0,0,1,2,3,0,0,0,0,2,1,0,0,0,2,3,4,0,0,0,0,0,0,0,2,3,4,0,0,0,1,2,3,0,0,0,0,2,1,0,0,0,2,3,4,0,
            0,0,4,0,0,0,0,2,0,0,0,0,0,3,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,4,0,0,0,0,2,0,0,0,0,0,3,0,0,0,0,0,0,4,0,0,
            8,8,8,8,8,0,8,8,8,8,8,0,8,8,8,8,8,0,8,8,8,8,8,0,0,0,0,0,8,8,8,8,8,0,8,8,8,8,8,0,8,8,8,8,8,0,8,8,8,8,8,
            0,0,6,0,0,0,0,4,0,0,0,0,0,0,0,7,0,0,0,0,6,0,0,0,0,0,0,0,0,0,6,0,0,0,0,4,0,0,0,0,0,0,0,7,0,0,0,0,6,0,0,
            0,0,7,0,0,0,0,5,6,7,0,0,0,9,8,0,0,0,0,0,7,0,0,0,0,0,0,0,0,0,7,0,0,0,0,5,6,7,0,0,0,9,8,0,0,0,0,0,7,0,0
        ];

        class TestGlyphRender: DiGlyphRender
        {
            DiGlyphParam param;
            void setParams( in DiGlyphParam p ){ param = p; }

            @property ImageType imtype() const
            { return ImageType( ImCompType.UBYTE, 1 ); }

            DiGlyphInfo render( wchar ch )
            {
                Image r;
                int offset = 6;
                ubyte[] dat;
                switch( ch )
                {
                    case "t"w[0]: 
                        dat = ( param.flag & param.Flag.STRIKED ) ? data_t_str : data_t;
                        r.allocate( imsize_t(5,5), imtype, dat ); 
                        offset = 6; 
                        break;
                    case "e"w[0]: 
                        dat = ( param.flag & param.Flag.STRIKED ) ? data_e_str : data_e;
                        r.allocate( imsize_t(5,5), imtype, dat); 
                        offset = 6; 
                        break;
                    case "s"w[0]: 
                        dat = ( param.flag & param.Flag.STRIKED ) ? data_s_str : data_s;
                        r.allocate( imsize_t(5,5), imtype, dat ); 
                        offset = 6; 
                        break;
                    default: r.allocate( imsize_t(3,5), imtype ); offset = 4; break;
                }
                return DiGlyphInfo( ivec2(0,-5), ivec2(offset,0), r );
            }
        }
    }
}

unittest
{
    auto tgr = new TestGlyphRender;
    auto bltr = new DiBaseLineTextRender;
    DiGlyphParam gp;
    auto res = bltr( tgr, gp, "test test" );

    assert( res.pos == ivec2( 0, -5 ) );
    assert( res.img.size.w == 51 );
    assert( res.img.size.h == 5 );

    auto timg = Image( imsize_t(51,5), tgr.imtype, data_test_test );

    assert( res.img == timg );

    gp.flag = gp.Flag.STRIKED;
    res = bltr( tgr, gp, "test test" );

    auto timg2 = Image( imsize_t(51,5), tgr.imtype, data_test_test_str );
    assert( res.img == timg2 );

}
