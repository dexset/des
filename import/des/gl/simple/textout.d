module des.gl.simple.textout;

import des.fonts;

import des.gl;

import std.traits;
import std.conv;
import std.string;

import des.util.logsys;
import des.util.arch.emm;

wstring wformat(S,Args...)( S fmt, Args args )
    if( is( S == string ) || is( S == wstring ) )
{ return to!wstring( format( to!string(fmt), args ) ); }

enum SS_WIN_TEXT =
`//### vert
#version 120
attribute vec2 vert;
attribute vec2 uv;

uniform ivec2 win_size;
uniform vec2 offset;

varying vec2 ex_uv;

void main(void)
{
    vec2 tr_vert = ( vert + offset ) / win_size * 2 - 1;
    gl_Position = vec4( tr_vert.x, -tr_vert.y, 0, 1);
    ex_uv = uv;
}
//### frag
#version 120
uniform sampler2D ttu;
uniform vec3 color;

varying vec2 ex_uv;

void main(void)
{
    gl_FragColor = vec4( color, texture2D( ttu, ex_uv ).r );
}`;

class BaseLineTextBox : GLDrawObject
{
private:

    CommonGLShaderProgram shader;

    public GLArrayBuffer vert, uv;

    GLTexture2D tex;

    wstring output;

    vec2 offset;

    BitmapFont font;

    float spacing = 1.5;

    fRegion2 rect;

    void update()
    {
        if( output.length == 0 ) return;

        vec2[] vert_data;
        vec2[] uv_data;

        vec2 ch_offset;
        auto fts = vec2( font.image.size );

        rect = fRegion2(0);

        foreach( c; output )
        {
            if( c == '\n' )
            {
                ch_offset.x = 0;
                ch_offset.y += font.height * spacing;
                continue;
            }

            if( c !in font.info )
            {
                logger.error( "Character "w ~ c ~ "not in bitmap font."w );
                continue;
            }

            auto chsz = vec2(font.info[c].glyph.size);
            auto p = ch_offset + font.info[c].glyph.pos;
            vert_data ~= computeRectPts( p, chsz );

            rect = rect.expand(p).expand(p+chsz);

            auto uvoffset = vec2( font.info[c].offset ) / fts;
            auto uvsize = chsz / fts;

            uv_data ~= computeRectPts( uvoffset, uvsize );

            ch_offset += font.info[c].glyph.next;
        }

        vert.setData( vert_data );
        uv.setData( uv_data );
    }

    vec2[] computeRectPts( vec2 v1, vec2 sz )
    {
        auto v2 = v1 + sz;
        return [ vec2( v1.x, v2.y ), v1, vec2( v2.x, v1.y ),
                 v2, vec2( v1.x, v2.y ), vec2( v2.x, v1.y ) ];
    }

public:

    this( string font_name, uint size=24u )
    {
        shader = newEMM!CommonGLShaderProgram( parseGLShaderSource( SS_WIN_TEXT ) );

        vert = newEMM!GLArrayBuffer;
        setAttribPointer( vert, shader.getAttribLocation( "vert" ), 2, GLType.FLOAT );

        uv = newEMM!GLArrayBuffer;
        setAttribPointer( uv, shader.getAttribLocation( "uv" ), 2, GLType.FLOAT );

        tex = newEMM!GLTexture2D(0);

        tex.setMinFilter( GLTexture.Filter.NEAREST );
        tex.setMagFilter( GLTexture.Filter.NEAREST );

        FontRenderParam gparam;
        gparam.height = size;

        auto grender = FTFontRender.get( font_name );

        grender.setParams( gparam );

        auto symbols = "!\"#$%&'()*+,-./0123456789:;<=>?@[\\]^_`{|}~^? "w;
        auto english = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"w;
        auto russian = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя"w;

        font = grender.generateBitmapFont( symbols ~ english ~ russian );

        tex.setImage( font.image );

        text = "Default text";
    }

    void draw( ivec2 win_size )
    {
        if( output.length == 0 ) return;
        shader.setUniform!ivec2( "win_size", win_size );
        tex.bind();
        glDisable(GL_DEPTH_TEST);
        drawArrays( DrawMode.TRIANGLES, 0, vert.elementCount );
        tex.unbind();
    }

    @property
    {
        void text(T)( T t ) if( isSomeString!T )
        {
            import std.conv;
            output = to!wstring( t );
            update();
        }

        wstring text(){ return output; }

        void position( vec2 pos )
        {
            offset = pos;
            shader.setUniform!vec2( "offset", offset );
        }

        vec2 position() const { return offset; }

        void color( vec3 col ){ shader.setUniform!vec3( "color", col ); }

        fRegion2 rectangle() const { return rect; }
    }
}
