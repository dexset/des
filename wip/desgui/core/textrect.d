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

module desgui.core.textrect;

import desgui.core.textrender;
import desgui.core.draw;
import desgui.core.except;

class DiTextRectException: DiException 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

class DiTextRect : DiDrawable
{
protected:
    DiTextRender textRender;
    DiGlyphRender glyphRender;

    DiGlyphInfo p_glyph;
    DiGlyphParam p_param;

    DiDrawRect p_plane;

    wstring p_text;

    ivec2 loffset = ivec2(0,0);

    final void repos()
    { p_plane.reshape( irect( p_glyph.pos + loffset, p_glyph.size ) ); }

    void update()
    {
        p_glyph = textRender( glyphRender, p_param, p_text );
        p_plane.image( p_glyph.img );
        repos();
    }

public:

    this( DiTextRender tr, DiGlyphRender gr, DiDrawRect dr ) 
    { 
        if( dr is null )
            throw new DiTextRectException( "draw rect for DiTextRect is null" );

        p_plane = dr;
        p_plane.useTexture = p_plane.UseTexture.FULL;

        setRenders( tr, gr );
    }

    @property
    {
        ivec2 pos() const { return loffset; }

        void pos( in ivec2 offset )
        { 
            loffset = offset;
            repos();
        }

        irect rect() const { return p_plane.rect; }

        ref const(DiGlyphInfo) glyph() const nothrow { return p_glyph; }

        wstring text() const nothrow { return p_text; }
        void text( wstring str ) 
        { 
            if( p_text != str )
            {
                p_text = str; 
                update(); 
            }
        }

        ref const(DiGlyphParam) param() const nothrow { return p_param; }
        void param( in DiGlyphParam par ) 
        { 
            if( p_param != par )
            {
                p_param = par; 
                update(); 
            }
        }
    }

    void draw() { p_plane.draw(); }

    void setRenders( DiTextRender tr, DiGlyphRender gr )
    {
        if( tr is null )
            throw new DiTextRectException( "text render for DiTextRect is null" );
        if( gr is null )
            throw new DiTextRectException( "glyph render for DiTextRect is null" );

        textRender = tr;
        glyphRender = gr;

        update();
    }
}

unittest
{
    import desil.image;
    import desgui.core.context;
    void printImage( in Image img )
    {
        import std.stdio;
        foreach( y; 0 .. img.size.h )
        {
            foreach( x; 0 .. img.size.w )
            {
                auto v = img.read!ubyte(x,y);
                char r;
                switch(v)
                {
                    case 0: r = '`'; break;
                    case 8: r = '#'; break;
                    default: r = '*'; break;
                }
                stderr.write( r );
            }
            stderr.writeln();
        }
        stderr.writeln();
    }

    auto tgr = new TestGlyphRender();
    auto bltr = new DiBaseLineTextRender();
    auto ddr = new TestDrawRect( irect(0,0,1,1) );
    
    auto dtr = new DiTextRect( bltr, tgr, ddr );

    auto im = Image( screen );
    dtr.text = "test test"w;
    dtr.draw();
    assert( screen == im );
    clearScreen();

    auto ttim = Image( imsize_t( 51,5 ), ImageType( ImCompType.UBYTE, 1 ), data_test_test );
    im = Image( screen );
    im.paste( ivec2(0,-2), ttim );
    dtr.pos = ivec2( 0, 3 );
    dtr.draw();

    assert( screen == im );
    clearScreen();

    auto ttimStr = Image( imsize_t( 51,5 ), ImageType( ImCompType.UBYTE, 1 ), data_test_test_str );
    im = Image( screen );
    im.paste( ivec2(4,3), ttimStr );
    dtr.pos = ivec2(4,8);
    assert( dtr.glyph.pos.x == 0 );
    assert( dtr.glyph.pos.y == -5 );
    assert( dtr.pos.x == 4 );
    assert( dtr.pos.y == 8 );
    auto np = DiGlyphParam( DiGlyphParam.Flag.STRIKED ); 
    dtr.param = np;
    assert( dtr.param.flag == DiGlyphParam.Flag.STRIKED );

    dtr.draw();
    assert( screen == im );
}
