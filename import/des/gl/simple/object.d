module des.gl.simple.object;

import std.exception;
import std.stdio;
import std.string;

public import des.gl.base;

abstract class GLSimpleObject : GLObject
{
private:
    size_t draw_count;
    size_t index_count;

    class GLArrayBuffer : GLBuffer
    {
        override void setUntypedData( in void[] data_arr, size_t element_size, Usage mem=Usage.DYNAMIC_DRAW )
        {
            super.setUntypedData( data_arr, element_size, mem );
            draw_count = elementCount;
        }

        this() { super( Target.ARRAY_BUFFER ); }
    }

    class GLIndexBuffer : GLBuffer
    {
        override void setUntypedData( in void[] data_arr, size_t element_size, Usage mem=Usage.DYNAMIC_DRAW )
        {
            enforce( element_size == uint.sizeof );
            super.setUntypedData( data_arr, uint.sizeof, mem );
            index_count = elementCount;
        }

        this() { super( Target.ELEMENT_ARRAY_BUFFER ); }
    }

protected:

    CommonShaderProgram shader;
    bool warn_if_empty = true;

    auto createArrayBuffer()
    { return registerChildEMM( new GLArrayBuffer ); }

    /+ ??? под вопросом +/
    static struct APInfo
    {
        string name;
        uint per_element;
        GLType type;
        size_t stride = 0;
        size_t offset = 0;
        bool required = true;

        this( string n, uint pe, GLType t, bool req=true )
        {
            name = n;
            per_element = pe;
            type = t; 
            required = req;
        }

        this( string n, uint pe, GLType t, size_t st, size_t of, bool req=true )
        {
            this( n, pe, t, req );
            stride = st;
            offset = of;
        }
    }

    /+ ??? под вопросом +/
    auto createArrayBuffersFromAttributeInfo( in APInfo[] infos... )
    {
        GLArrayBuffer[string] ret;
        foreach( info; infos )
        {
            auto loc = shader.getAttribLocation( info.name );

            if( loc < 0 )
            {
                if( info.required )
                    assert( 0, format( "no attrib '%s' in shader", info.name ) );
                else continue;
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
    { return registerChildEMM( new GLIndexBuffer ); }

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

    void preDraw() { vao.bind(); }

    void drawArrays( DrawMode mode )
    {
        preDraw();
        if( draw_count > 0 )
            glDrawArrays( mode, 0, cast(uint)draw_count );
        else if( warn_if_empty )
            stderr.writeln( "WARNING: draw empty object" );

        debug checkGL;
    }

    void drawElements( DrawMode mode )
    {
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

