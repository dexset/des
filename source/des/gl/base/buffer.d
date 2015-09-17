module des.gl.base.buffer;

import std.c.string;

import derelict.opengl3.gl3;

import des.gl.base.type;

import des.stdx;

///
class GLBufferException : DesGLException
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

///
class GLBuffer : DesObject
{
    mixin DES;
    mixin ClassLogger;

protected:
    uint _id;
    Target type;

    ///
    size_t data_size;
    ///
    uint element_count;

    ///
    GLenum gltype() const nothrow @property { return cast(GLenum)type; }

public:

    ///
    enum Usage
    {
        STREAM_DRAW  = GL_STREAM_DRAW,  /// `GL_STREAM_DRAW`
        STREAM_READ  = GL_STREAM_READ,  /// `GL_STREAM_READ`
        STREAM_COPY  = GL_STREAM_COPY,  /// `GL_STREAM_COPY`
        STATIC_DRAW  = GL_STATIC_DRAW,  /// `GL_STATIC_DRAW`
        STATIC_READ  = GL_STATIC_READ,  /// `GL_STATIC_READ`
        STATIC_COPY  = GL_STATIC_COPY,  /// `GL_STATIC_COPY`
        DYNAMIC_DRAW = GL_DYNAMIC_DRAW, /// `GL_DYNAMIC_DRAW`
        DYNAMIC_READ = GL_DYNAMIC_READ, /// `GL_DYNAMIC_READ`
        DYNAMIC_COPY = GL_DYNAMIC_COPY  /// `GL_DYNAMIC_COPY`
    }

    ///
    enum Access
    {
        READ_ONLY  = GL_READ_ONLY,  /// `GL_READ_ONLY`
        WRITE_ONLY = GL_WRITE_ONLY, /// `GL_WRITE_ONLY`
        READ_WRITE = GL_READ_WRITE  /// `GL_READ_WRITE`
    }

    ///
    enum Target
    {
        ARRAY_BUFFER              = GL_ARRAY_BUFFER,              /// `GL_ARRAY_BUFFER`
        ATOMIC_COUNTER_BUFFER     = GL_ATOMIC_COUNTER_BUFFER,     /// `GL_ATOMIC_COUNTER_BUFFER`
        COPY_READ_BUFFER          = GL_COPY_READ_BUFFER,          /// `GL_COPY_READ_BUFFER`
        COPY_WRITE_BUFFER         = GL_COPY_WRITE_BUFFER,         /// `GL_COPY_WRITE_BUFFER`
        DRAW_INDIRECT_BUFFER      = GL_DRAW_INDIRECT_BUFFER,      /// `GL_DRAW_INDIRECT_BUFFER`
        DISPATCH_INDIRECT_BUFFER  = GL_DISPATCH_INDIRECT_BUFFER,  /// `GL_DISPATCH_INDIRECT_BUFFER`
        ELEMENT_ARRAY_BUFFER      = GL_ELEMENT_ARRAY_BUFFER,      /// `GL_ELEMENT_ARRAY_BUFFER`
        PIXEL_PACK_BUFFER         = GL_PIXEL_PACK_BUFFER,         /// `GL_PIXEL_PACK_BUFFER`
        PIXEL_UNPACK_BUFFER       = GL_PIXEL_UNPACK_BUFFER,       /// `GL_PIXEL_UNPACK_BUFFER`
        SHADER_STORAGE_BUFFER     = GL_SHADER_STORAGE_BUFFER,     /// `GL_SHADER_STORAGE_BUFFER`
        TEXTURE_BUFFER            = GL_TEXTURE_BUFFER,            /// `GL_TEXTURE_BUFFER`
        TRANSFORM_FEEDBACK_BUFFER = GL_TRANSFORM_FEEDBACK_BUFFER, /// `GL_TRANSFORM_FEEDBACK_BUFFER`
        UNIFORM_BUFFER            = GL_UNIFORM_BUFFER             /// `GL_UNIFORM_BUFFER`  
    }

    /// `glBindBuffer( trg, 0 )`
    static nothrow void unbind( Target trg )
    { glBindBuffer( cast(GLenum)trg, 0 ); }

    ///
    this( Target tp=Target.ARRAY_BUFFER )
    {
        checkGLCall!glGenBuffers( 1, &_id );
        type = tp;

        logger = new InstanceLogger( this, format( "%d", _id ) );

        logger.Debug( "type [%s]", type );
    }

    final
    {
        /// `glBindBuffer`
        void bind()
        {
            checkGLCall!glBindBuffer( gltype, _id );
            debug logger.trace( "type [%s]", type );
        }

        /// `glBindBuffer` with self target to 0
        void unbind()
        {
            checkGLCall!glBindBuffer( gltype, 0 );
            debug logger.trace( "type [%s]", type );
        }

        ///
        uint id() @property const { return _id; }
    }

    /++ calls when element count changed (in setUntypedData)
     +
     + See_Also: `setUntypedData`
     +/
    Signal!uint elementCountCB;

    /++ calls when element size changed (in setUntypedData)
     +
     + See_Also: `setUntypedData`
     +/
    Signal!uint elementSizeCB;

    /++ calls when data size changed (in setUntypedData)
     +
     + See_Also: `setUntypedData`
     +/
    Signal!size_t dataSizeCB;

    /++ `bind`, `glBufferData`, `unbind`
     +  call signals:
     +  `elementCountCB`
     +  `elementSizeCB`
     +  `dataSizeCB`
     +/
    void setUntypedData( in void[] data_arr, size_t element_size, Usage mem=Usage.DYNAMIC_DRAW )
    {
        auto size = data_arr.length;
        if( !size ) throw new GLBufferException( "set buffer data size is 0" );

        bind();
        checkGLCall!glBufferData( gltype, size, data_arr.ptr, cast(GLenum)mem );

        element_count = cast(uint)( data_arr.length / element_size );
        data_size = size;

        elementCountCB( cast(uint)element_count );
        dataSizeCB( data_size );
        elementSizeCB( cast(uint)element_size );

        debug logger.trace( "[%s]: size [%d], element size [%d], usage [%s]",
                type, size, element_size, mem );

        unbind();
    }

    /// `setUntypedData( data_arr, E.sizeof, mem )`
    void setData(E)( in E[] data_arr, Usage mem=Usage.DYNAMIC_DRAW )
    { setUntypedData( data_arr, E.sizeof, mem ); }

    /// `bind`, `glBufferSubData`, `unbind`
    void setSubUntypedData( size_t offset, in void[] data_arr, size_t element_size )
    {
        auto size = data_arr.length;

        if( !size ) throw new GLBufferException( "set sub buffer data size is 0" );
        if( offset + size > data_size )
            throw new GLBufferException( "set sub buffer data: offset+size > data_size" );

        bind();
        checkGLCall!glBufferSubData( gltype, offset, size, data_arr.ptr );

        debug logger.trace( "[%s]: offset [%d], size [%d], element size [%d]",
                type, offset, size, element_size );

        unbind();
    }

    /// `setSubUntypedData( offset * E.sizeof, data_arr, E.sizeof )`
    void setSubData(E)( size_t offset, in E[] data_arr )
    { setSubUntypedData( offset * E.sizeof, data_arr, E.sizeof ); }

    /// return ubtyped copy of buffer data
    void[] getUntypedData()
    {
        auto mp = mapUntypedData( Access.READ_ONLY );
        auto buf = new void[]( data_size );
        memcpy( buf.ptr, mp.ptr, data_size );
        unmap();
        return buf;
    }

    /// cast untyped copy of buffer data to `E[]`
    E[] getData(E)() { return cast(E[])getUntypedData(); }

    /// return untyped copy of buffer sub data
    void[] getSubUntypedData( size_t offset, size_t length )
    {
        auto mp = mapUntypedDataRange( offset, length, Access.READ_ONLY );
        auto buf = new void[]( length );
        memcpy( buf.ptr, mp.ptr, length );
        unmap();
        return buf;
    }

    /// cast untyped copy of buffer sub data to `E[]`
    E[] getSubData(E)( size_t offset, size_t count )
    { return cast(E[])getSubUntypedData( E.sizeof * offset, E.sizeof * count ); }

    @property
    {
        const final
        {
            ///
            uint elementCount() { return element_count; }
            ///
            size_t dataSize() { return data_size; }

            /// calculated
            uint elementSize()
            { return cast(uint)( element_count ? data_size / element_count : 0 ); }
        }
    }

    /// `bind`, `glMapBuffer`, `unbind`
    ArrayData mapUntypedData( Access access=Access.READ_ONLY )
    {
        debug logger.trace( "by access [%s]", access );
        bind();
        scope(exit) unbind();
        return ArrayData( data_size, checkGLCall!glMapBuffer( gltype, cast(GLenum)access ) );
    }

    /// `bind`, `glMapBufferRange`, `unbind`
    ArrayData mapUntypedDataRange( size_t offset, size_t length, Access access=Access.READ_ONLY )
    { 
        if( offset + length > data_size )
            throw new GLBufferException( "map buffer range: offset + length > data_size" );
        debug logger.trace( "by access [%s]: offset [%d], length [%d]", access, offset, length );
        bind();
        scope(exit) unbind();
        return ArrayData( length, checkGLCall!glMapBufferRange( gltype, offset, length, cast(GLenum)access ) );
    }

    ///
    AlienArray!E mapData(E)( Access access )
    { return getTypedArray!E( mapUntypedData( access ) ); }

    ///
    AlienArray!E mapDataRange(E)( size_t offset, size_t length, Access access ) 
    { return getTypedArray!E( mapUntypedDataRange( offset * E.sizeof, length * E.sizeof, access ) ); }

    /// `bind`, `glUnmapBuffer`, `unbind`
    void unmap()
    {
        bind();
        checkGLCall!glUnmapBuffer( gltype );
        debug logger.trace( "pass" );
        unbind();
    }

protected:

    override void selfDestroy()
    {
        checkGLCall!glDeleteBuffers( 1, &_id );
        debug logger.Debug( "pass" );
    }
}

///
class GLIndexBuffer : GLBuffer
{
    ///
    this() { super( Target.ELEMENT_ARRAY_BUFFER ); }

    /// throw exception if element size != uint.sizeof
    override void setUntypedData( in void[] data_arr, size_t element_size, Usage mem=Usage.DYNAMIC_DRAW )
    {
        enforce( element_size == uint.sizeof, new GLBufferException( "element size != uint.sizeof" ) );
        super.setUntypedData( data_arr, element_size, mem );
    }

    /// throw exception if element size != uint.sizeof
    override void setSubUntypedData( size_t offset, in void[] data_arr, size_t element_size )
    {
        enforce( element_size == uint.sizeof, new GLBufferException( "element size != uint.sizeof" ) );
        super.setSubUntypedData( offset, data_arr, element_size );
    }
}
