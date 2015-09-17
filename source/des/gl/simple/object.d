module des.gl.simple.object;

import std.exception;
import std.stdio;
import std.string;

public import des.gl.base;

///
abstract class GLSimpleObject : GLObject
{
private:
    uint draw_count;
    uint index_count;

    GLBuffer elem_buffer = null;

protected:

    ///
    void setDrawCount( uint cnt ) { draw_count = cnt; }

    ///
    void setIndexCount( uint cnt ) { index_count = cnt; }

    ///
    CommonGLShaderProgram shader;

    ///
    bool warn_if_empty = true;

    ///
    auto createArrayBuffer()
    {
        auto buf = newEMM!GLBuffer( GLBuffer.Target.ARRAY_BUFFER );
        connect( buf.elementCountCB, &setDrawCount );
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
                    logger.warn( "no attrib '%s' in shader", info.attrib );
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

    ///
    auto createIndexBuffer()
    {
        auto buf = newEMM!GLBuffer( GLBuffer.Target.ELEMENT_ARRAY_BUFFER );
        connect( buf.elementCountCB, &setIndexCount );
        connect( buf.elementSizeCB, (uint sz){
            enforce( sz == uint.sizeof, "set to index buffer not uint data" );
        });
        elem_buffer = buf;
        return buf;
    }

    ///
    override void preDraw()
    {
        shader.use();
        if( elem_buffer !is null )
            elem_buffer.bind();
        debug checkGL;
    }

    ///
    void drawArrays( DrawMode mode )
    {
        if( !visible ) return;
        if( draw_count > 0 )
            super.drawArrays( mode, cast(uint)draw_count );
        else if( warn_if_empty )
            logger.warn( "simple object draw empty object" );
    }

    ///
    void drawElements( DrawMode mode )
    {
        if( !visible ) return;
        if( index_count > 0 && draw_count > 0 )
            super.drawElements( mode, cast(uint)index_count );
        else if( warn_if_empty )
            logger.warn( "simple object draw empty object" );
    }

public:

    ///
    this( string shader_source )
    {
        shader = newEMM!CommonGLShaderProgram( parseGLShaderSource( shader_source ) );
    }

    ///
    bool visible = true;

    ///
    this( CommonGLShaderProgram sh )
    in{ assert( sh !is null ); } body
    { shader = sh; }
}
