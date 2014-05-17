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

module desgui.core.label;

import desgui.core.widget;
import desgui.core.textrect;

class DiLabelException: DiException 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

class DiLabel: DiWidget
{
protected:
    DiTextRect textrect;

    DiGlyphRender glyphRender;
    DiTextRender textRender;

    void repos()
    {
        int hoffset = 0;
        if( textalign != TextAlign.LEFT )
        {
            int sum = textrect.glyph.next.x;
            hoffset = ( textalign == TextAlign.RIGHT ) ? 
                rect.w - sum :
                (rect.w - sum) / 2;
        }
        textrect.pos = ivec2( hoffset, rect.h * baselineCoef );
    }

    final void updateRenders()
    { textrect.setRenders( textRender, glyphRender ); repos(); }

    TextAlign textalign = TextAlign.LEFT;

    float heightCoef = 0.7;
    float baselineCoef = 0.8;

    ivec2 oldsize;

public:

    enum TextAlign { LEFT, CENTER, RIGHT };

    this( DiWidget par, in irect rr, wstring str="" )
    {
        super( par );
        textRender = new DiBaseLineTextRender;
        glyphRender = ctx.baseGlyphRender();
        textrect = new DiTextRect( textRender, glyphRender, ctx.draw.rect() );

        draw.connect({ textrect.draw(); });

        reshape.connect( (r)
        { 
            if( r.size.x == oldsize.x && r.size.y == oldsize.y ) return;
            DiGlyphParam p = textrect.param;
            p.height = cast(uint)( rect.h * heightCoef );
            textrect.param = p;
            repos();
            oldsize = r.size;
        });

        processEventMask = 0;

        textrect.text = str;
        reshape( rr );
    }

    @property 
    {
        void textAlign( TextAlign ta ) { textalign = ta; repos(); }
        TextAlign textAlign() const { return textalign; }

        void text( wstring str ) { textrect.text = str; repos(); }
        wstring text() const { return textrect.text; }

        void color( in col4 clr ) 
        { 
            if( textrect.param.color == clr ) return;
            DiGlyphParam buf = textrect.param;
            buf.color = clr;
            textrect.param = buf;
            repos();
        }
        col4 color() const { return textrect.param.color; }
    }

    void setGlyphRender( DiGlyphRender gr )
    {
        if( glyphRender == gr ) return;
        glyphRender = gr;
        updateRenders();
    }

    void setTextRender( DiTextRender tr )
    {
        if( textRender == tr ) return;
        textRender = tr;
        updateRenders();
    }
}
