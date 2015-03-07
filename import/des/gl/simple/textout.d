module des.gl.simple.textout;

import des.fonts.ftglyphrender;

import des.gl.base;
import des.gl.simple.shader.text;

import std.traits;
import std.conv;
import std.string;

import des.util.logsys;
import des.util.arch.emm;

wstring wformat(S,Args...)( S fmt, Args args )
    if( is( S == string ) || is( S == wstring ) )
{ return to!wstring( format( to!string(fmt), args ) ); }

class BaseLineTextBox : GLDrawObject
{
private:

    CommonGLShaderProgram shader;

    GLArrayBuffer vert, uv;

    GLTexture tex;

    wstring output;
    vec2 output_size;

    vec2 pos;

    BitmapFont font;

    void repos()
    {
        if( output.length == 0 )
            return;
        vec2[] vert_data;
        vec2[] uv_data;

        output_size = vec2(0);

        float offsetx = 0;

        foreach( c; output )
        {
            if( c !in font.info ) continue;
            if( font.info[c].size.h > output_size.h )
                output_size.h = font.info[c].size.h;
        }

        foreach( c; output )
        {
            if( c !in font.info )
            {
                logger.error( "Character "w ~ c ~ "not in bitmap font."w );
                continue;
            }

            output_size.w += font.info[c].next.w;

            {
                auto v1 = pos + vec2( font.info[c].pos.x + offsetx, output_size.h + font.info[c].pos.y );
                auto v2 = v1 + font.info[c].size;

                vert_data ~= vec2( v1.x, v2.y );
                vert_data ~= v1;
                vert_data ~= vec2( v2.x, v1.y );

                vert_data ~= v2;
                vert_data ~= vec2( v1.x, v2.y );
                vert_data ~= vec2( v2.x, v1.y );

                offsetx += font.info[c].next.x;
            }

            {
                auto uvoffset = vec2( font.info[c].offset ) / vec2( font.texture.size );
                auto uvsize = vec2( font.info[c].size ) / vec2( font.texture.size );

                auto uv1 = uvoffset;
                auto uv2 = uv1 + uvsize;

                uv_data ~= vec2( uv1.x, uv2.y );
                uv_data ~= uv1;
                uv_data ~= vec2( uv2.x, uv1.y );

                uv_data ~= uv2;
                uv_data ~= vec2( uv1.x, uv2.y );
                uv_data ~= vec2( uv2.x, uv1.y );
            }
        }

        vert.setData( vert_data );
        uv.setData( uv_data );
    }

public:
    this( string font_name, uint size=24u )
    {
        shader = newEMM!CommonGLShaderProgram( parseGLShaderSource( SS_WIN_TEXT ) );

        vert = newEMM!GLArrayBuffer;
        setAttribPointer( vert, shader.getAttribLocation( "vert" ), 2, GLType.FLOAT );

        uv = newEMM!GLArrayBuffer;
        setAttribPointer( uv, shader.getAttribLocation( "uv" ), 2, GLType.FLOAT );

        tex = newEMM!GLTexture( GLTexture.Target.T2D );

        tex.setMinFilter( GLTexture.Filter.NEAREST );
        tex.setMagFilter( GLTexture.Filter.NEAREST );

        GlyphParam gparam;
        gparam.height = size;

        auto grender = FTGlyphRender.get( font_name );

        grender.setParams( gparam );

        auto symbols = "!\"#$%&'()*+,-./0123456789:;<=>?@[\\]^_`{|}~^? "w;
        auto english = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"w;
        auto russian = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя"w;

        font = grender.generateBitmapFont( symbols ~ english ~ russian );

        tex.image( font.texture );

        text = "Default text";
    }

    void draw( ivec2 win_size )
    {
        if( output.length == 0 )
            return;
        shader.setUniform!ivec2( "win_size", win_size );
        tex.bind();
        glDisable(GL_DEPTH_TEST);
        drawArrays( DrawMode.TRIANGLES, 0, vert.elementCount );
        tex.unbind();
    }

    @property
    {
        void text(T)( T t )
            if( isSomeString!T )//TODO is convertable to wstring
        {
            import std.conv;
            output = to!wstring( t );
            repos();
        }
        wstring text(){ return output; }

        void position( vec2 pos )
        {
            this.pos = pos;
            repos();
        }

        void color( vec3 col ){ shader.setUniform!vec3( "color", col ); }

        vec2 size(){ return output_size; }
    }
}

class BaseMultiLineTextBox : ExternalMemoryManager
{
    mixin EMM;
private:
    BaseLineTextBox[] lines;

    wstring output;
    vec2 output_size;
    vec2 pos;

    string font_name;
    uint font_size;

    void repos()
    {
        foreach( ref l; lines )
            l.destroy();
        lines.destroy();
        auto ll = output.split( "\n" );
        float ysize = 0;
        float xsize = 0;
        foreach( i, l; ll )
        {
            lines ~= newEMM!BaseLineTextBox( font_name, font_size );
            lines[$-1].text = l;
            lines[$-1].color = col;
            lines[$-1].position = pos + vec2( 0, i * font_size );
            if( lines[$-1].size.x > xsize )
                xsize = lines[$-1].size.x;
            ysize += lines[$-1].size.y;
        }

        output_size = vec2( xsize, ysize );
    }

    vec3 col;
public:
    this( string font_name, uint font_size = 24u )
    {
        this.font_name = font_name;
        this.font_size = font_size;

        text =
`Default
Multi
Line
Text`;
    }

    void draw( ivec2 win_size )
    {
        foreach( l; lines )
            l.draw( win_size );
    }

    @property
    {
        void text(T)( T t )
            if( isSomeString!T )
        {
            output = to!wstring( t );
            repos();
        }
        wstring text(){ return output; }

        void position( vec2 pos )
        {
            this.pos = pos;
            repos();
        }

        void color( vec3 col ){ this.col = col; }

        vec2 size(){ return output_size; }
    }
}
