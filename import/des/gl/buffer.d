module des.gl.buffer;

import des.gl.general;

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

            bool isMapped() { return is_mapped; }
        }
    }

    /// `bind`, `glUnmapBuffer`, `unbind`
    void unmap()
    {
        bind();
        checkGLCall!glUnmapBuffer( target );
        debug logger.trace( "pass" );
        unbind();
        is_mapped = false;
    }

    /++ provides:
     + * `void setRaw( in void[] arr, size_t esize, Usage mem=Usage.STATIC_DRAW )`
     + * `void setSubRaw( size_t offset, in void[] arr )`
     + * `void storageRaw( in void[] arr, size_t esize, StorageBits[] bits )`
     +/
    mixin template RawSet()
    {
        public
        {
            void setRaw( in void[] arr, size_t esize, Usage mem=Usage.STATIC_DRAW )
            { setRawData( arr, esize, mem ); }

            void setSubRaw( size_t offset, in void[] arr )
            { setRawSubData( offset, arr ); }

            void storageRaw( in void[] arr, size_t esize, StorageBits[] bits )
            { setStorage( arr, esize, bits ); }

            void allocRaw( size_t count, size_t esize, StorageBits[] bits )
            { allocStorage( count, esize, bits ); }
        }
    }

    mixin template RawGet()
    {
        public void[] getRaw( size_t offset=0, size_t size=0 )
        { return getRawSubData( offset, size ); }
    }

    mixin template RawMap()
    {
        public
        {
            void[] mapRaw( in MapBits[] bits )
            { return mapRawDataRange( 0, data_size, bits ); }

            void[] mapRangeRaw( size_t offset, size_t length, in MapBits[] bits )
            { return mapRawDataRange( offset, length, bits ); }

            void flushRangeRaw( size_t offset, size_t length, size_t esize=1 )
            { flushRawMappedRange( offset, length, esize ); }
        }
    }

    mixin template RawAccess()
    {
        mixin RawSet;
        mixin RawGet;
        mixin RawMap;
    }

    mixin template TemplateSet()
    {
        public
        {
            void setData(E)( in E[] arr, Usage mem=Usage.STATIC_DRAW )
            { setRawData( arr, E.sizeof, mem ); }

            void setSubData(E)( size_t offset, in E[] arr )
            {
                auto es = E.sizeof;
                if( es != elementSize )
                    logger.error( "mismatch element size" );
                setRawSubData( offset * es, arr );
            }

            void storageData(E)( in E[] arr, StorageBits[] bits )
            { setStorage( arr, E.sizeof, bits ); }

            void allocData(E)( size_t count, StorageBits[] bits )
            { allocStorage( count, E.sizeof, bits ); }
        }
    }

    mixin template TemplateGet()
    {
        public E[] getData(E)( size_t offset=0, size_t count=0 )
        { return cast(E[])getRawSubData( offset * E.sizeof, count * E.sizeof ); }
    }

    mixin template TemplateMap()
    {
        public
        {
            E[] mapData(E)( in MapBits[] bits )
            { return cast(E[])mapRawDataRange( 0, data_size, bits ); }

            E[] mapRangeData(E)( size_t offset, size_t length, in MapBits[] bits )
            {
                auto es = E.sizeof;
                return cast(E[])mapRawDataRange( offset*es, length*es, bits );
            }

            void flushRangeData(E)( size_t offset, size_t length )
            {
                auto es = E.sizeof;
                flushRawMappedRange( offset*es, length*es, es );
            }
        }
    }

    mixin template TemplateAccess()
    {
        mixin TemplateSet;
        mixin TemplateGet;
        mixin TemplateMap;
    }

    mixin template TypeSet(T,string postFix="")
    {
        mixin( format(q{
        public
        {
            static if( !is(typeof(setType%1$s)) )
                protected void setType%1$s() {}

            void set( in T[] arr, Usage mem=Usage.STATIC_DRAW )
            {
                setRawData( arr, T.sizeof, mem );
                setType%1$s();
            }

            void setSub( size_t offset, in T[] arr )
            {
                auto es = T.sizeof;
                if( es != elementSize )
                    logger.error( "mismatch element size" );
                setRawSubData( offset * es, arr );
                setType%1$s();
            }

            void storage( in T[] arr, in StorageBits[] bits )
            {
                setStorage( arr, T.sizeof, bits );
                setType%1$s();
            }

            void alloc%1$s( size_t count, in StorageBits[] bits )
            {
                allocStorage( count * T.sizeof, T.sizeof, bits );
                setType%1$s();
            }
        }
        }, postFix ));
    }

    mixin template TypeGet(T,string postFix="")
    {
        mixin( format(q{
        public T[] get%1$s( size_t offset=0, size_t count=0 )
        { return cast(T[])getRawSubData( offset * T.sizeof, count * T.sizeof ); }
        }, postFix ));
    }

    mixin template TypeMap(T,string postFix="")
    {
        mixin( format(q{
        public
        {
            T[] mapRange%1$s( size_t offset, size_t length, in MapBits[] bits )
            {
                auto es = T.sizeof;
                return cast(T[])mapRawDataRange( offset * es, length*es, bits );
            }

            T[] map%1$s( in MapBits[] bits )
            { return cast(T[])mapRawDataRange( 0, data_size, bits ); }

            void flushRange%1$s( size_t offset, size_t length )
            {
                auto es = T.sizeof;
                flushRawMappedRange( offset*es, length*es, es );
            }
        }
        }, postFix ));
    }

    mixin template TypeAccess(T,string postFix="")
    {
        mixin TypeSet!(T,postFix);
        mixin TypeGet!(T,postFix);
        mixin TypeMap!(T,postFix);
    }

protected:

    //===== sets =====

    /// `bind`, `glBufferData`, `unbind`
    void setRawData( in void[] data_arr, size_t element_size, Usage mem )
    {
        auto size = data_arr.length;
        if( !size ) throw new GLBufferException( "set buffer data size is 0" );

        bind(); scope(exit) unbind();
        checkGLCall!glBufferData( target, size, data_arr.ptr, mem );

        element_count = cast(uint)( data_arr.length / element_size );
        data_size = size;

        debug logger.trace( "size [%db : %d by %db], usage [%s]", size, element_count, element_size, mem );
    }

    /// `bind`, `glBufferSubData`, `unbind`
    void setRawSubData( size_t offset, in void[] data_arr )
    {
        auto size = data_arr.length;

        if( !size ) throw new GLBufferException( "set sub buffer data size is 0" );
        if( offset + size > data_size )
            throw new GLBufferException( "set sub buffer data: offset+size > data_size" );

        bind(); scope(exit) unbind();
        checkGLCall!glBufferSubData( target, offset, size, data_arr.ptr );

        debug logger.trace( "offset [%d], size [%d]", offset, size );
    }

    ///
    void setStorage( in void[] data, size_t elem_size, in StorageBits[] bits )
    {
        bind(); scope(exit) unbind();
        element_count = cast(uint)( data.length / elem_size );
        data_size = data.length;
        checkGLCall!glBufferStorage( target, data.length, data.ptr, packBitMask(bits) );
        debug logger.trace( "by bits %s: size [%d : %d x %d]", bits, data_size, element_count, elementSize );
    }

    ///
    void allocStorage( size_t elem_count, size_t elem_size, in StorageBits[] bits )
    {
        bind(); scope(exit) unbind();
        element_count = cast(uint)elem_count;
        data_size = elem_count * elem_size;
        checkGLCall!glBufferStorage( target, data_size, null, packBitMask(bits) );
        debug logger.trace( "by bits %s: size [%d : %d x %d]", bits, data_size, element_count, elementSize );
    }

    //===== gets =====

    /++ return untyped copy of buffer data
     +
     +  if `size == 0` returns data with `dataSize - offset` length
     +/
    void[] getRawSubData( size_t offset=0, size_t size=0 )
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

    //===== maps =====

    bool is_mapped = false;

    /// `bind`, `glMapBufferRange`, `unbind`
    void[] mapRawDataRange( size_t offset, size_t length, in MapBits[] bits )
    {
        if( offset + length > data_size )
            throw new GLBufferException( "map buffer range: offset + length > data_size" );
        if( bits.length == 0 )
            throw new GLBufferException( "map buffer range must accept bits" );

        debug logger.trace( "by bits %s: offset [%d], length [%d]", bits, offset, length );

        bind();
        scope(exit)
        {
            unbind();
            is_mapped = true;
        }

        return getTypedArray!void( length, checkGLCall!glMapBufferRange( target, offset, length, packBitMask(bits) ) );
    }

    ///
    void flushRawMappedRange( size_t offset, size_t length, size_t elem_size=1 )
    {
        bind(); scope(exit) unbind();
        checkGLCall!glFlushMappedBufferRange( target, offset * elem_size, length * elem_size );
        debug logger.trace( "offset [%d], length [%d], elem_size [%d]", offset, length, elem_size );
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
void copyBufferSubData( GLBuffer readbuf, GLBuffer writebuf, uint readoffset, uint writeoffset, uint size )
{
    bindCopyReadBuffer( readbuf );
    bindCopyWriteBuffer( writebuf );
    checkGLCall!glCopyBufferSubData( GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER,
                                     readoffset, writeoffset, size );
    unbindCopyReadBuffer();
    unbindCopyWriteBuffer();
}

///
class GLArrayBuffer : GLBuffer
{
    ///
    this() { super( GL_ARRAY_BUFFER ); }

    mixin RawAccess;
    mixin TemplateAccess;
}

// TODO
//class GLDispatchIndirectBuffer : GLBuffer
//{
//    ///
//    this() { super( GL_DISPATCH_INDIRECT_BUFFER ); }
//}

///
class GLDrawIndirectBuffer : GLBuffer
{
    ///
    this() { super( GL_DRAW_INDIRECT_BUFFER ); }

    ///
    struct ArrayCmd
    {
        ///
        uint count;
        ///
        uint instanceCount;
        ///
        uint first;
        ///
        uint baseInstance;
    }

    ///
    struct ElementCmd
    {
        /// indices count
        uint count;
        ///
        uint instanceCount;
        /// offset in index array
        uint firstIndex;
        ///
        uint baseVertex;
        /// not affect to glsl `gl_InstanceID`, only attrib divisor
        uint baseInstance;
    }

    mixin TypeAccess!(ArrayCmd,"Array");
    mixin TypeAccess!(ElementCmd,"Element");
}

///
class GLElementArrayBuffer : GLBuffer
{
protected:

    Type _type;

    void setTypeByte()  { _type = Type.UBYTE; }
    void setTypeShort() { _type = Type.USHORT; }
    void setTypeInt()   { _type = Type.UINT; }

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

    mixin TypeAccess!(ubyte,"Byte");
    mixin TypeAccess!(ushort,"Short");
    mixin TypeAccess!(uint,"Int");
}

// TODO
//class GLPixelPackBuffer : GLBuffer
//{
//    ///
//    this() { super( GL_PIXEL_PACK_BUFFER ); }
//}

// TODO
//class GLPixelUnpackBuffer : GLBuffer
//{
//    ///
//    this() { super( GL_PIXEL_UNPACK_BUFFER ); }
//}

// TODO
//class GLQueryBuffer : GLBuffer
//{
//    ///
//    this() { super( GL_QUERY_BUFFER ); }
//}

// TODO
//class GLTextureBuffer : GLBuffer
//{
//    ///
//    this() { super( GL_TEXTURE_BUFFER ); }
//}

///
abstract class GLIndexedBuffer : GLBuffer
{
private:
    bool target_setted = false;

public:

    this( GLenum trg )
    {
        super(trg);
        target_setted = true;
    }

    invariant()
    {
        if( target_setted )
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

// TODO
//class GLAtomicCounterBuffer : GLIndexedBuffer
//{
//    ///
//    this() { super( GL_ATOMIC_COUNTER_BUFFER ); }
//}

// TODO
//class GLTransformFeedbackBuffer : GLIndexedBuffer
//{
//    ///
//    this() { super( GL_TRANSFORM_FEEDBACK_BUFFER ); }
//}

///
class GLUniformBuffer : GLIndexedBuffer
{
    ///
    this() { super( GL_UNIFORM_BUFFER ); }

    mixin RawAccess;
    mixin TemplateAccess;
}

///
class GLShaderStorageBuffer : GLIndexedBuffer
{
    ///
    this() { super( GL_SHADER_STORAGE_BUFFER ); }

    mixin RawAccess;
    mixin TemplateAccess;
}
