module des.gl.base.object;

import std.c.string;

import derelict.opengl3.gl3;

import des.gl.base.type;
import des.gl.base.buffer;

import des.util.data.type;

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

pure:
    ///
    this( string name, int location, uint elements,
          GLType type=GLType.FLOAT,
          size_t stride=0, size_t offset=0 )
    {
        this.name     = name;
        this.location = location;
        this.elements = elements;
        this.type     = type;
        this.stride   = stride;
        this.offset   = offset;
    }

    size_t dataSize() const @property
    {
        if( stride ) return stride;
        return elements * sizeofGLType( type );
    }
}

/// Vertex Array Object
final class GLVAO : DesObject
{
    mixin DES;
    mixin ClassLogger;

protected:
    uint _id;

    int[int] aaset;

public:
    ///
    static nothrow void unbind(){ glBindVertexArray(0); }

    /// `glGenVertexArrays`
    this()
    {
        checkGLCall!glGenVertexArrays( 1, &_id );
        logger = new InstanceLogger( this, format( "%d", _id ) );
        logger.Debug( "pass" );
    }

    ///
    int[] enabled() const @property { return aaset.keys; }

    nothrow
    {
        /// `glBindVertexArray`
        void bind()
        {
            ntCheckGLCall!glBindVertexArray( _id );
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

protected:

    /// `glDeleteVertexArrays`
    override void selfDestroy() { glDeleteVertexArrays( 1, &_id ); }
}

///
class GLObject : DesObject
{
    mixin DES;
    mixin ClassLogger;

protected:
    ///
    GLVAO vao;

    final
    {
        /// `glVertexAttribPointer`
        void setAttribPointer( GLBuffer buffer, int index, uint per_element,
                GLType attype, size_t stride, size_t offset, bool norm=false )
        {
            vao.enable( index );

            buffer.bind();
            checkGLCall!glVertexAttribPointer( index, cast(int)per_element,
                    cast(GLenum)attype, norm, cast(int)stride, cast(void*)offset );

            logger.Debug( "VAO [%d], buffer [%d], "~
                            "index [%d], per element [%d][%s]"~
                            "%s%s",
                            vao._id, buffer.id,
                            index, per_element, attype,
                            stride != 0 ? ntFormat(", stride [%d], offset [%d]", stride, offset ) : "",
                            norm ? ntFormat( ", norm [%s]", norm ) : "" );

            buffer.unbind();
        }

        /// ditto
        void setAttribPointer( GLBuffer buffer, int index, uint per_element,
                GLType attype, bool norm=false )
        { setAttribPointer( buffer, index, per_element, attype, 0, 0, norm ); }

        /// ditto
        void setAttribPointer( GLBuffer buffer, in GLAttrib attr )
        {
            setAttribPointer( buffer, attr.location, attr.elements,
                              attr.type, attr.stride, attr.offset );
        }
    }

    /// override this for any action before draw
    void preDraw() {}

    ///
    void drawArrays( DrawMode mode, uint count, uint start=0 )
    {
        vao.bind();
        preDraw();
        checkGLCall!glDrawArrays( mode, start, count );
        debug logger.trace( "mode [%s], count [%d]", mode, count );
    }

    ///
    void drawElements( DrawMode mode, uint count )
    {
        vao.bind();
        preDraw();
        checkGLCall!glDrawElements( mode, count, GL_UNSIGNED_INT, null );
        debug logger.trace( "mode [%s], count [%d]", mode, count );
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
class GLMeshObject : GLObject
{
protected:

    ///
    uint num_vertices;

    ///
    GLIndexBuffer indices;

    ///
    GLBuffer[] buffers;

public:

    ///
    this( in GLMeshData md ) { prepareMesh( md ); }

protected:

    /// creates buffers, set vertices count, etc
    void prepareMesh( in GLMeshData data )
    {
        num_vertices = data.num_vertices;

        if( data.indices.length )
        {
            indices = newEMM!GLIndexBuffer();
            indices.setData( data.indices );
            logger.Debug( "indices count: ", data.indices.length );
            import std.algorithm;
            logger.Debug( "indices max: ", reduce!max( data.indices ) );
        }

        foreach( bufdata; data.buffers )
            if( auto buf = prepareBuffer( bufdata, data.attribs ) )
                buffers ~= buf;
    }

    /// create buffer, set attrib pointer, set data if exists
    GLBuffer prepareBuffer( in GLMeshData.Buffer bd, in GLAttrib[] attrlist )
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
    GLBuffer createArrayBuffer()
    { return newEMM!GLBuffer( GLBuffer.Target.ARRAY_BUFFER ); }
}
