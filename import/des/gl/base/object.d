module des.gl.base.object;

import des.gl.base.general;
import des.gl.base.buffer;

///
class GLObjException : DesGLException
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

///
struct GLAttrib
{
    ///
    string name;

    /// by default invalid value < 0
    int location = -1;
    ///
    uint elements;
    ///
    GLType type;
    ///
    size_t stride;
    ///
    size_t offset;
    ///
    bool norm;

pure:
    ///
    this( string name, int location, uint elements,
          GLType type=GLType.FLOAT,
          size_t stride=0, size_t offset=0, bool norm=false )
    {
        this.name     = name;
        this.location = location;
        this.elements = elements;
        this.type     = type;
        this.stride   = stride;
        this.offset   = offset;
        this.norm     = norm;
    }

    size_t dataSize() const @property
    {
        if( stride ) return stride;
        return elements * sizeofGLType( type );
    }
}

/// Vertex Array Object
final class GLVAO : GLObject!("VertexArray",false)
{
protected:

    int[int] aaset;

public:
    ///
    static nothrow void unbind(){ glBindVertexArray(0); }

    /// `glGenVertexArrays`
    this()
    {
        super(0);
        logger.Debug( "pass" );
    }

    ///
    int[] enabled() const @property { return aaset.keys; }

    /// `glBindVertexArray( id )`
    override void bind()
    {
        checkGLCall!glBindVertexArray( id );
        debug logger.trace( "pass" );
    }

    /// `glBindVertexArray( 0 )`
    override void unbind()
    {
        checkGLCall!glBindVertexArray( 0 );
        debug logger.trace( "pass" );
    }

    /// `glEnableVertexAttribArray`
    void enable( int n )
    {
        debug scope(exit) logger.Debug( "[%d]", n );
        if( n < 0 ) return;
        bind();
        ntCheckGLCall!glEnableVertexAttribArray( n );
        aaset[n] = n;
    }

    /// `glDisableVertexAttribArray`
    void disable( int n )
    {
        debug scope(exit) logger.Debug( "[%d]", n );
        if( n < 0 ) return;
        bind();
        ntCheckGLCall!glDisableVertexAttribArray( n );
        aaset.remove(n);
    }
}

///
class GLDrawObject : DesObject
{
    mixin DES;
    mixin ClassLogger;

protected:
    ///
    GLVAO vao;

    final
    {
        /// `glVertexAttribPointer`
        void setAttribPointer( GLArrayBuffer buffer, int index, uint per_element,
                GLType attype, size_t stride, size_t offset, bool norm=false )
        {
            vao.enable( index );

            buffer.bind(); scope(exit) buffer.unbind();

            checkGLCall!glVertexAttribPointer( index, cast(int)per_element,
                    cast(GLenum)attype, norm, cast(int)stride, cast(void*)offset );

            logger.Debug( "VAO [%d], buffer [%d], "~
                            "index [%d], per element [%d][%s]"~
                            "%s%s",
                            vao.id, buffer.id,
                            index, per_element, attype,
                            stride != 0 ? ntFormat(", stride [%d], offset [%d]", stride, offset ) : "",
                            norm ? ntFormat( ", norm [%s]", norm ) : "" );
        }

        /// ditto
        void setAttribPointer( GLArrayBuffer buffer, int index, uint per_element,
                GLType attype, bool norm=false )
        { setAttribPointer( buffer, index, per_element, attype, 0, 0, norm ); }

        /// ditto
        void setAttribPointer( GLArrayBuffer buffer, in GLAttrib attr )
        {
            setAttribPointer( buffer, attr.location, attr.elements,
                              attr.type, attr.stride, attr.offset, attr.norm );
        }
    }

    /// override this for any action before draw
    void preDraw() {}

    ///
    void drawArrays( DrawMode mode, uint start, uint count )
    {
        vao.bind();
        preDraw();
        checkGLCall!glDrawArrays( mode, start, count );
        debug logger.trace( "mode [%s], start [%d], count [%d]", mode, start, count );
    }

    /// by default has no index buffer
    bool bindElementArrayBuffer() { return false; }

    ///
    void drawElements( DrawMode mode, GLElementArrayBuffer eab )
    {
        if( eab is null )
        {
            logger.error( "element array buffer is null" );
            return;
        }

        vao.bind();
        eab.bind();

        preDraw();

        checkGLCall!glDrawElements( mode, eab.elementCount, cast(GLenum)eab.type, null );
        debug logger.trace( "mode [%s]", mode );
    }

public:

    ///
    this()
    {
        vao = newEMM!GLVAO;
        debug checkGL;
    }

    ///
    enum DrawMode
    {
        POINTS                   = GL_POINTS,                  /// `GL_POINTS`
        LINES                    = GL_LINES,                   /// `GL_LINES`
        LINE_STRIP               = GL_LINE_STRIP,              /// `GL_LINE_STRIP`
        LINE_LOOP                = GL_LINE_LOOP,               /// `GL_LINE_LOOP`
        TRIANGLES                = GL_TRIANGLES,               /// `GL_TRIANGLES`
        TRIANGLE_STRIP           = GL_TRIANGLE_STRIP,          /// `GL_TRIANGLE_STRIP`
        TRIANGLE_FAN             = GL_TRIANGLE_FAN,            /// `GL_TRIANGLE_FAN`
        LINES_ADJACENCY          = GL_LINES_ADJACENCY,         /// `GL_LINES_ADJACENCY`
        LINE_STRIP_ADJACENCY     = GL_LINE_STRIP_ADJACENCY,    /// `GL_LINE_STRIP_ADJACENCY`
        TRIANGLES_ADJACENCY      = GL_TRIANGLES_ADJACENCY,     /// `GL_TRIANGLES_ADJACENCY`
        TRIANGLE_STRIP_ADJACENCY = GL_TRIANGLE_STRIP_ADJACENCY /// `GL_TRIANGLE_STRIP_ADJACENCY`
    }
}

///
struct GLMeshData
{
    ///
    GLDrawObject.DrawMode draw_mode;

    ///
    uint num_vertices;

    ///
    uint[] indices;

    ///
    GLAttrib[] attribs;

    ///
    static struct Buffer
    {
        ///
        void[] data;
        /// numbers of attributes in `GLMeshData.attribs` array
        uint[] attribs;
    }

    ///
    Buffer[] buffers;
}

///
class GLMeshObject : GLDrawObject
{
protected:

    ///
    uint num_vertices;

    ///
    GLElementArrayBuffer indices;

    ///
    GLArrayBuffer[] arrays;

    DrawMode draw_mode;

public:

    ///
    this( in GLMeshData md ) { prepareMesh( md ); }

protected:

    /// with `draw_mode` and `num_vertices`
    void drawArrays() { super.drawArrays( draw_mode, 0, num_vertices ); }

    /// with `draw_mode` and `indices.elementCount`
    void drawElements() { super.drawElements( draw_mode, indices ); }

    /// creates buffers, set vertices count, etc
    void prepareMesh( in GLMeshData data )
    {
        draw_mode = data.draw_mode;

        num_vertices = data.num_vertices;

        if( data.indices.length )
        {
            indices = newEMM!GLElementArrayBuffer();
            indices.set( data.indices );
            logger.Debug( "indices count: ", data.indices.length );
            import std.algorithm;
            logger.Debug( "indices max: ", reduce!max( data.indices ) );
        }

        foreach( bufdata; data.buffers )
            if( auto buf = prepareBuffer( bufdata, data.attribs ) )
                arrays ~= buf;
    }

    /// create buffer, set attrib pointer, set data if exists
    GLArrayBuffer prepareBuffer( in GLMeshData.Buffer bd, in GLAttrib[] attrlist )
    {
        if( bd.data is null )
        {
            logger.warn( "buffer is defined, but has no data" );
            return null;
        }

        if( bd.attribs is null )
        {
            logger.warn( "buffer is defined, but has no attribs" );
            return null;
        }

        auto buf = createArrayBuffer();
        buf.setUntypedData( bd.data, attrlist[bd.attribs[0]].dataSize,
                            GLBuffer.Usage.STATIC_DRAW );

        foreach( attr_no; bd.attribs )
        {
            auto attr = attrlist[attr_no];
            setAttribPointer( buf, attr );
            logger.Debug( "set attrib '%s' at loc '%d'", attr.name, attr.location );
        }

        return buf;
    }

    /// override if want to create specific buffers
    GLArrayBuffer createArrayBuffer() { return newEMM!GLArrayBuffer(); }
}
