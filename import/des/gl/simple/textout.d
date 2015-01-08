module des.gl.simple.textout;

import des.il.region;

import des.fonts.ftglyphrender;
import des.fonts.textrender;

import des.util.helpers;
import des.util.stdext.algorithm;

import des.gl.simple.shader.text;
import des.gl.simple.object;

wstring wformat(S,Args...)( S fmt, Args args )
    if( is( S == string ) || is( S == wstring ) )
{ return to!wstring( format( to!string(fmt), args ) ); }

class TextBox : GLSimpleObject
{
private:

    GLBuffer pos, color, uv;

    GLTexture tex;

    MultilineTextRender trender;
    GlyphRender grender;

    GlyphParam param;
    GlyphInfo info;

    wstring output;

    void redraw()
    {
        grender.setParams( param );
        tex.image( info.img );
    }

    void checkStretched()
    {
        if( stretched )
        {
            trect = rrect;
            param.height = cast(ubyte)( trect.size.y / cast(float)(lines) );
            redraw();
            repos();
        }
        info = trender( grender, param, output );
        if( !stretched )
        {
            trect = fRegion2( trect.x, trect.y, info.img.size.w, info.img.size.h );
            repos();
        }
    }

    void repos()
    {
        pos.setData( [ vec2(trect.x, trect.y),         vec2(trect.x+trect.w, trect.y),
                       vec2(trect.x, trect.y+trect.h), vec2(trect.x+trect.w, trect.y+trect.h) ] );
    }

    ulong lines;

    fRegion2 trect;
    fRegion2 rrect;

    bool stretched = false;

    //TODO move to simple
    void setAttrib( GLBuffer buffer, string name, uint per_element, GLType attype )
    { setAttribPointer( buffer, shader.getAttribLocation(name), per_element, attype ); }


    uint someSampler;
public:
    this( string fname, uint size=24u )
    {
        super( SS_WIN_TEXT );
        auto font = fname;

        grender = FTGlyphRender.get(font);
        trender = new MultilineTextRender;
        trender.offset = 3;

        pos = newEMM!GLBuffer;
        color = newEMM!GLBuffer;
        uv = newEMM!GLBuffer;

        setAttrib( pos, "pos", 2, GLType.FLOAT );
        setAttrib( color, "color", 4, GLType.FLOAT );
        setAttrib( uv, "uv", 2, GLType.FLOAT );

        setColor( col4( 1.0, 1.0, 1.0, 1.0 ) );

        uv.setData([ vec2( 0.0, 0.0 ), vec2( 1.0, 0.0 ),
                     vec2( 0.0, 1.0 ), vec2( 1.0, 1.0 ) ]);


        setDrawCount( 4 );

        tex = new GLTexture( GLTexture.Target.T2D );

        tex.setParameter( GLTexture.Parameter.MIN_FILTER, GLTexture.Filter.NEAREST );
        tex.setParameter( GLTexture.Parameter.MAG_FILTER, GLTexture.Filter.NEAREST );

        text = "";
        tex.image( info.img );
        textHeight = size;
    }

    void draw( in ivec2 wsz )
    {
        tex.bind();
        shader.setUniform!vec2( "winsize", vec2(wsz) );
  
        glDisable(GL_DEPTH_TEST);

        drawArrays( DrawMode.TRIANGLE_STRIP );

        tex.unbind();
    }

    void setRect( fRegion2 r )
    {
        trect = r;
        rrect = r;
        checkStretched();
        repos();
    }

    void setColor( col4 color )
    { setColor( amap!( a => color )( new col4[](4) ) ); }

    void setColor( col4[] color ... )
    { this.color.setData( color ); }

    @property
    {
        void text( wstring t )
        {
            import std.string;
            output = t;
            lines = t.split("\n").length;
            checkStretched();
            redraw();
        }

        wstring text() const { return output; }

        void textHeight( uint hh )
        {
            param.height = hh;
            checkStretched();
            redraw();
        }

        uint textHeight() const { return param.height; }

        void isStretched( bool s )
        { 
            stretched = s; 
            checkStretched();
            redraw();
        }
        bool isStretched() const { return stretched; }
    }
}
