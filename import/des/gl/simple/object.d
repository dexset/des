module des.gl.simple.object;

import std.exception;
import std.stdio;
import std.string;

public import des.gl.base;
import des.gl.util;

abstract class GLSimpleObject : GLObject
{
private:
    size_t draw_count;
    size_t index_count;

protected:

    void setDrawCount( size_t cnt )
    { draw_count = cnt; }

    void setIndexCount( size_t cnt )
    { index_count = cnt; }

    CommonShaderProgram shader;
    bool warn_if_empty = true;

    auto createArrayBuffer()
    {
        auto buf = registerChildEMM( new GLBuffer( GLBuffer.Target.ARRAY_BUFFER ) );
        buf.elementCountCallback = &setDrawCount;
        return buf;
    }

    /+ ??? под вопросом +/
    static struct APInfo
    {
        string name;
        string attrib;
        uint per_element;
        GLType type;
        size_t stride = 0;
        size_t offset = 0;
        bool required = true;

        this( string n, uint pe, GLType t, bool req=true )
        {
            name = n;
            attrib = n;
            per_element = pe;
            type = t; 
            required = req;
        }

        this( string n, string a, uint pe, GLType t, size_t st, size_t of, bool req=true )
        {
            this( n, pe, t, req );
            attrib = a;
            stride = st;
            offset = of;
        }
    }

    /+ ??? под вопросом +/
    auto createArrayBuffersFromAttributeInfo( in APInfo[] infos... )
    {
        GLBuffer[string] ret;
        foreach( info; infos )
        {
            auto loc = shader.getAttribLocation( info.attrib );

            if( loc < 0 )
            {
                if( info.required )
                    assert( 0, format( "no attrib '%s' in shader", info.attrib ) );
                else
                {
                    stderr.writefln( "no attrib '%s' in shader", info.attrib );
                    continue;
                }
            }

            if( info.name !in ret )
                ret[info.name] = createArrayBuffer();
                
            auto buf = ret[info.name];
            setAttribPointer( buf, loc, info.per_element, info.type,
                              info.stride, info.offset );
        }
        return ret;
    }

    auto createIndexBuffer()
    {
        auto buf = registerChildEMM( new GLBuffer( GLBuffer.Target.ELEMENT_ARRAY_BUFFER ) );
        buf.elementCountCallback = &setIndexCount;
        buf.elementSizeCallback = (sz){
            enforce( sz == uint.sizeof, "set to index buffer not uint data" );
        };
        return buf;
    }

    enum DrawMode
    {
        POINTS = GL_POINTS,
        LINE_STRIP = GL_LINE_STRIP,
        LINE_LOOP = GL_LINE_LOOP,
        LINES = GL_LINES,
        LINE_STRIP_ADJACENCY = GL_LINE_STRIP_ADJACENCY,
        LINES_ADJACENCY = GL_LINES_ADJACENCY,
        TRIANGLE_STRIP = GL_TRIANGLE_STRIP,
        TRIANGLE_FAN = GL_TRIANGLE_FAN,
        TRIANGLES = GL_TRIANGLES,
        TRIANGLE_STRIP_ADJACENCY = GL_TRIANGLE_STRIP_ADJACENCY,
        TRIANGLES_ADJACENCY = GL_TRIANGLES_ADJACENCY,
    }

    bool draw_flag = true;

    void preDraw()
    {
        vao.bind();
        shader.use();
        debug checkGL;
    }

    void drawArrays( DrawMode mode )
    {
        if( !draw_flag ) return;
        preDraw();
        if( draw_count > 0 )
            glDrawArrays( mode, 0, cast(uint)draw_count );
        else if( warn_if_empty )
            stderr.writeln( "WARNING: draw empty object" );

        debug checkGL;
    }

    void drawElements( DrawMode mode )
    {
        if( !draw_flag ) return;
        preDraw();
        if( index_count > 0 && draw_count > 0 )
            glDrawElements( mode, cast(uint)index_count, GL_UNSIGNED_INT, null );
        else if( warn_if_empty )
            stderr.writeln( "WARNING: draw empty object" );

        debug checkGL;
    }

public:

    this( in ShaderSource ss )
    { shader = registerChildEMM( new CommonShaderProgram(ss) ); }

    this( CommonShaderProgram sh )
    in{ assert( sh !is null ); } body
    { shader = sh; }
}

