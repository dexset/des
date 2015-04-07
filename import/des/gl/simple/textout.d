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
#version 330
in vec2 vert;
in vec2 uv;

uniform ivec2 win_size;
uniform vec2 offset;

out vec2 ex_uv;

void main(void)
{
    vec2 tr_vert = ( vert + offset ) / win_size * 2 - 1;
    gl_Position = vec4( tr_vert.x, -tr_vert.y, 0, 1);
    ex_uv = uv;
}
//### frag
#version 330
uniform sampler2DRect ttu;
uniform vec4 color;

in vec2 ex_uv;

out vec4 result;

void main(void)
{
    result = vec4( 1,1,1, texture( ttu, ivec2( ex_uv.x, ex_uv.y ) ).r ) * color;
}`;

class BaseLineTextBox : GLDrawObject
{
private:

    CommonGLShaderProgram shader;

    public GLArrayBuffer vert, uv;

    GLTextureRectangle tex;

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

        auto ch_offset = vec2(0);

        rect = fRegion2(0);

        std.stdio.writeln( font.height );
        std.stdio.writeln( font.image.size );

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

            auto chsz = vec2( font.info[c].glyph.size );
            auto p = ch_offset + font.info[c].glyph.pos;
            vert_data ~= computeRectPts( p, chsz );

            rect = rect.expand(p).expand(p+chsz);

            auto buf = computeRectPts( vec2( font.info[c].offset ), chsz );

            if( font.height != 16 )
            std.stdio.writeln( buf );

            uv_data ~= buf;

            ch_offset += font.info[c].glyph.next;
        }

        std.stdio.writeln();

        vert.setData( vert_data );
        uv.setData( uv_data );
    }

    auto computeRectPts(T)( in Vector!(2,T) v1, in Vector!(2,T) sz )
    {
        alias VV=Vector!(2,T);
        auto v2 = v1 + sz;
        return [ v1, VV( v1.x, v2.y ), VV( v2.x, v1.y ),
                 v2, VV( v2.x, v1.y ), VV( v1.x, v2.y ) ];
        //return [ VV( v1.x, v2.y ), v1, VV( v2.x, v1.y ),
        //         v2, VV( v1.x, v2.y ), VV( v2.x, v1.y ) ];
    }

public:

    this( string font_name, uint size=24u )
    {
        shader = newEMM!CommonGLShaderProgram( parseGLShaderSource( SS_WIN_TEXT ) );

        vert = newEMM!GLArrayBuffer;
        setAttribPointer( vert, shader.getAttribLocation( "vert" ), 2, GLType.FLOAT );

        uv = newEMM!GLArrayBuffer;
        setAttribPointer( uv, shader.getAttribLocation( "uv" ), 2, GLType.FLOAT );

        tex = newEMM!GLTextureRectangle(0);

        tex.setMinFilter( GLTexture.Filter.NEAREST );
        tex.setMagFilter( GLTexture.Filter.NEAREST );

        FontRenderParam gparam;
        gparam.height = size;

        auto grender = FTFontRender.get( font_name );

        auto symbols = "!\"#$%&'()*+,-./0123456789:;<=>?@[\\]^_`{|}~^? "w;
        auto english = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"w;
        auto russian = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя"w;

        grender.setParams( gparam );
        font = grender.generateBitmapFont( symbols ~ english ~ russian );

        tex.setImage( font.image );
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

        void color( vec4 col ){ shader.setUniform!vec4( "color", col ); }

        fRegion2 rectangle() const { return rect; }
    }
}
