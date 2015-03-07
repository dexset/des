module des.gl.base.buffer;

import des.gl.base.general;

///
class GLBufferException : DesGLException
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

///
abstract class GLBuffer : GLObject!"Buffer"
{
protected:

    ///
    size_t data_size;
    ///
    uint element_count;

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
    enum MapBits
    {
        READ  = GL_MAP_READ_BIT,  /// `GL_MAP_READ_BIT`
        WRITE = GL_MAP_WRITE_BIT, /// `GL_MAP_WRITE_BIT`

        PERSISTENT = GL_MAP_PERSISTENT_BIT, /// `GL_MAP_PERSISTENT_BIT`
        COHERENT   = GL_MAP_COHERENT_BIT,   /// `GL_MAP_COHERENT_BIT`

        INVALIDATE_RANGE  = GL_MAP_INVALIDATE_RANGE_BIT,  /// `GL_MAP_INVALIDATE_RANGE_BIT`
        INVALIDATE_BUFFER = GL_MAP_INVALIDATE_BUFFER_BIT, /// `GL_MAP_INVALIDATE_BUFFER_BIT`
        FLUSH_EXPLICIT    = GL_MAP_FLUSH_EXPLICIT_BIT,    /// `GL_MAP_FLUSH_EXPLICIT_BIT`
        UNSYNCHRONIZED    = GL_MAP_UNSYNCHRONIZED_BIT     /// `GL_MAP_UNSYNCHRONIZED_BIT`
    }

    ///
    enum StorageBits
    {
        READ  = GL_MAP_READ_BIT,  /// `GL_MAP_READ_BIT`
        WRITE = GL_MAP_WRITE_BIT, /// `GL_MAP_WRITE_BIT`

        PERSISTENT = GL_MAP_PERSISTENT_BIT, /// `GL_MAP_PERSISTENT_BIT`
        COHERENT   = GL_MAP_COHERENT_BIT,   /// `GL_MAP_COHERENT_BIT`

        DYNAMIC = GL_DYNAMIC_STORAGE_BIT, /// `GL_DYNAMIC_STORAGE_BIT`
        CLIENT  = GL_CLIENT_STORAGE_BIT,  /// `GL_CLIENT_STORAGE_BIT`
    }

    ///
    this( GLenum trg )
    {
        super( trg );
        logger.Debug( "pass" );
    }

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

    //===== sets =====

    /// `bind`, `glBufferData`, `unbind`
    void setUntypedData( in void[] data_arr, size_t element_size, Usage mem=Usage.DYNAMIC_DRAW )
    {
        auto size = data_arr.length;
        if( !size ) throw new GLBufferException( "set buffer data size is 0" );

        bind(); scope(exit) unbind();
        checkGLCall!glBufferData( target, size, data_arr.ptr, cast(GLenum)mem );

        element_count = cast(uint)( data_arr.length / element_size );
        data_size = size;

        debug logger.trace( "size [%db : %d by %db], usage [%s]", size, element_count, element_size, mem );
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

        bind(); scope(exit) unbind();
        checkGLCall!glBufferSubData( target, offset, size, data_arr.ptr );

        debug logger.trace( "[%s]: offset [%d], size [%d], element size [%d]",
                target, offset, size, element_size );
    }

    /// `setSubUntypedData( offset * E.sizeof, data_arr, E.sizeof )`
    void setSubData(E)( size_t offset, in E[] data_arr )
    { setSubUntypedData( offset * E.sizeof, data_arr, E.sizeof ); }

    //===== gets =====

    /// return untyped copy of buffer data
    void[] getUntypedData( size_t offset=0, size_t size=0 )
    {
        ptrdiff_t sz = size ? size : cast(ptrdiff_t)dataSize - offset;

        auto buf = new void[]( sz );
        bind();
        checkGLCall!glGetBufferSubData( target, offset, sz, buf.ptr );
        unbind();

        debug
        {
            auto es = elementSize;

            if( offset % es ) logger.warn( "offset is not a multiple of element size" );
            if( size % es ) logger.warn( "size is not a multiple of element size" );

            logger.trace( "[%s]: offset [%d], size [%d], offset in elements [%d], size in elements [%d]",
                target, offset, sz, offset / es, sz / es );
        }

        return buf;
    }

    /// cast untyped copy of buffer data to `E[]`
    E[] getData(E)( size_t offset=0, size_t count=0 )
    {
        debug if( E.sizeof != elementSize )
            logger.warn( "mismatch sizes of type %s [%d] and element size [%d]",
                    E.stringof, E.sizeof, elementSize );

        return cast(E[])getUntypedData( E.sizeof * offset, E.sizeof * count );
    }

    //===== maps =====

    /// `bind`, `glMapBufferRange`, `unbind`
    void[] mapUntypedDataRange( size_t offset, size_t length, in MapBits[] bits... )
    {
        if( offset + length > data_size )
            throw new GLBufferException( "map buffer range: offset + length > data_size" );

        debug logger.trace( "by bits %s: offset [%d], length [%d]", bits, offset, length );

        bind(); scope(exit) unbind();

        return getTypedArray!void( length, checkGLCall!glMapBufferRange( target, offset, length, packBitMask(bits) ) );
    }

    ///
    E[] mapDataRange(E)( size_t offset, size_t length, in MapBits[] bits... )
    { return cast(E[])mapUntypedDataRange( offset * E.sizeof, length * E.sizeof, bits ); }

    /// `bind`, `glMapBufferRange( 0, data_size )`, `unbind`
    void[] mapUntypedData( in MapBits[] bits... )
    { return mapUntypedDataRange( 0, data_size, bits ); }

    ///
    E[] mapData(E)( in MapBits[] bits... )
    { return cast(E[])mapUntypedDataRange( 0, data_size, bits ); }

    /// `bind`, `glUnmapBuffer`, `unbind`
    void unmap()
    {
        bind();
        checkGLCall!glUnmapBuffer( target );
        debug logger.trace( "pass" );
        unbind();
    }

    ///
    void flushMappedRange( size_t offset, size_t length, size_t elem_size=1 )
    {
        bind(); scope(exit) unbind();
        checkGLCall!glFlushMappedBufferRange( target, offset * elem_size, length * elem_size );
        debug logger.trace( "offset [%d], length [%d], elem_size [%d]", offset, length, elem_size );
    }

    ///
    void storage( void[] data, StorageBits[] bits... )
    {
        bind(); scope(exit) unbind();
        checkGLCall!glBufferStorage( target, data.length, data.ptr, packBitMask(bits) );
    }

    ///
    void storage( size_t size, StorageBits[] bits... )
    {
        bind(); scope(exit) unbind();
        checkGLCall!glBufferStorage( target, size, null, packBitMask(bits) );
    }
}

///
void bindCopyReadBuffer( GLBuffer buf )
{ checkGLCall!glBindBuffer( GL_COPY_READ_BUFFER, buf.id ); }

///
void unbindCopyReadBuffer()
{ checkGLCall!glBindBuffer( GL_COPY_READ_BUFFER, 0 ); }

///
void bindCopyWriteBuffer( GLBuffer buf )
{ checkGLCall!glBindBuffer( GL_COPY_WRITE_BUFFER, buf.id ); }

///
void unbindCopyWriteBuffer()
{ checkGLCall!glBindBuffer( GL_COPY_WRITE_BUFFER, 0 ); }

///
class GLArrayBuffer : GLBuffer
{
    ///
    this() { super( GL_ARRAY_BUFFER ); }
}

///
class GLDispatchIndirectBuffer : GLBuffer
{
    ///
    this() { super( GL_DISPATCH_INDIRECT_BUFFER ); }
}

///
class GLDrawIndirectBuffer : GLBuffer
{
    ///
    this() { super( GL_DRAW_INDIRECT_BUFFER ); }
}

///
class GLElementArrayBuffer : GLBuffer
{
private:

    bool inner_call = false;

protected:

    Type _type;

public:

    ///
    enum Type : GLType
    {
        UBYTE  = GLType.UBYTE, /// `GL_UNSIGNED_BYTE`
        USHORT = GLType.USHORT, /// `GL_UNSIGNED_SHORT`
        UINT   = GLType.UINT, /// `GL_UNSIGNED_INT`
    }

    final nothrow pure const @nogc @property
    {
        GLType type() { return _type; }
    }

    ///
    this() { super( GL_ELEMENT_ARRAY_BUFFER ); }

    override void setUntypedData( in void[] data, size_t es, Usage mem=Usage.DYNAMIC_DRAW )
    {
        enforce( inner_call, new GLBufferException( "forbiden not inner call, use 'set' method" ) );
        super.setUntypedData( data, es, mem );
    }

    ///
    void set(T)( in T[] data, Usage mem=Usage.STATIC_DRAW )
        if( is( T == ubyte ) || is( T == ushort ) || is( T == uint ) )
    {
        inner_call = true;
        setUntypedData( data, T.sizeof, mem );
        inner_call = false;
        _type = cast(Type)toGLType!T;
    }
}

///
class GLPixelPackBuffer : GLBuffer
{
    ///
    this() { super( GL_PIXEL_PACK_BUFFER ); }
}

///
class GLPixelUnpackBuffer : GLBuffer
{
    ///
    this() { super( GL_PIXEL_UNPACK_BUFFER ); }
}

///
class GLQueryBuffer : GLBuffer
{
    ///
    this() { super( GL_QUERY_BUFFER ); }
}

///
class GLTextureBuffer : GLBuffer
{
    ///
    this() { super( GL_TEXTURE_BUFFER ); }
}

///
abstract class GLIndexedBuffer : GLBuffer
{
public:

    this( GLenum trg ) { super(trg); }

    invariant()
    {
        assert( isValidIndexedTarget( _target ) );
    }

    /// calls `glBindBufferBase`
    void bindBase( uint index )
    {
        checkGLCall!glBindBufferBase( target, index, id );
        debug logger.trace( "index [%d]", index );
    }

    /// calls `glBindBufferRange`
    void bindRange( uint index, size_t offset, size_t size )
    {
        checkGLCall!glBindBufferRange( target, index, id, offset, size );
        debug logger.trace( "index [%d], offset [%d], size [%d]", index, offset, size );
    }

private:

    ///
    bool isValidIndexedTarget( GLenum trg ) const nothrow
    {
        switch( trg )
        {
            case GL_ATOMIC_COUNTER_BUFFER:
            case GL_TRANSFORM_FEEDBACK_BUFFER:
            case GL_UNIFORM_BUFFER:
            case GL_SHADER_STORAGE_BUFFER:
                return true;
            default:
                return false;
        }
    }
}

///
class GLAtomicCounterBuffer : GLIndexedBuffer
{
    ///
    this() { super( GL_ATOMIC_COUNTER_BUFFER ); }
}

///
class GLTransformFeedbackBuffer : GLIndexedBuffer
{
    ///
    this() { super( GL_TRANSFORM_FEEDBACK_BUFFER ); }
}

///
class GLUniformBuffer : GLIndexedBuffer
{
    ///
    this() { super( GL_UNIFORM_BUFFER ); }
}

///
class GLShaderStorageBuffer : GLIndexedBuffer
{
    ///
    this() { super( GL_SHADER_STORAGE_BUFFER ); }
}
