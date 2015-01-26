module des.gl.simple.textout;

import des.fonts.ftglyphrender;

import des.gl.simple;
import des.gl.simple.shader.text;

import std.traits;

wstring wformat(S,Args...)( S fmt, Args args )
    if( is( S == string ) || is( S == wstring ) )
{ return to!wstring( format( to!string(fmt), args ) ); }

class BaseLineTextBox : GLSimpleObject
{
private:

    GLBuffer vert, uv;

    GLTexture tex;

    wstring output;
    vec2 output_size;

    vec2 pos;

    BitmapFont font;

    void repos()
    {
        vec2[] vert_data;
        vec2[] uv_data;

        output_size = vec2(0);

        float offsetx = 0;
        foreach( c; output )
            if( font.size[c].h > output_size.h )
                output_size.h = font.size[c].h;
        
        foreach( c; output )
        {
            output_size.w += font.size[c].w;

            {
                auto v1 = pos + vec2( font.bearing[c].x + offsetx, output_size.h + font.bearing[c].y );
                auto v2 = v1 + font.size[c];

                vert_data ~= vec2( v1.x, v2.y );
                vert_data ~= v1;
                vert_data ~= vec2( v2.x, v1.y );

                vert_data ~= v2;
                vert_data ~= vec2( v1.x, v2.y );
                vert_data ~= vec2( v2.x, v1.y );

                offsetx += font.size[c].x;
            }

            {
                auto uvoffset = vec2( font.offset[c] ) / vec2( font.texture.size );
                auto uvsize = vec2( font.size[c] ) / vec2( font.texture.size );

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
        super( SS_WIN_TEXT );

        vert = createArrayBuffer();
        setAttribPointer( vert, shader.getAttribLocation( "vert" ), 2, GLType.FLOAT );

        uv = createArrayBuffer();
        setAttribPointer( uv, shader.getAttribLocation( "uv" ), 2, GLType.FLOAT );

        tex = newEMM!GLTexture( GLTexture.Target.T2D );

        tex.setParameter( GLTexture.Parameter.MIN_FILTER, GLTexture.Filter.NEAREST );
        tex.setParameter( GLTexture.Parameter.MAG_FILTER, GLTexture.Filter.NEAREST );

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
        shader.setUniform!ivec2( "win_size", win_size );
        tex.bind();
            glDisable(GL_DEPTH_TEST);
            drawArrays( DrawMode.TRIANGLES );
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

        void color( col3 col ){ shader.setUniform!col3( "color", col ); }

        vec2 size(){ return output_size; }
    }
}
