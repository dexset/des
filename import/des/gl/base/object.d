/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

module des.gl.base.object;

import std.c.string;

import derelict.opengl3.gl3;

import des.gl.util.ext;
import des.gl.base.type;

import des.util;

class GLObjException : DesGLException 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

class GLBuffer : ExternalMemoryManager
{
    mixin DirectEMM;
    mixin ClassLogger;

protected:
    uint _id;
    Target type;

    size_t data_size;
    size_t element_count;

    nothrow @property GLenum gltype() const { return cast(GLenum)type; }

public:

    enum Usage
    {
        STREAM_DRAW = GL_STREAM_DRAW,
        STREAM_READ = GL_STREAM_READ,
        STREAM_COPY = GL_STREAM_COPY,
        STATIC_DRAW = GL_STATIC_DRAW,
        STATIC_READ = GL_STATIC_READ,
        STATIC_COPY = GL_STATIC_COPY,
        DYNAMIC_DRAW = GL_DYNAMIC_DRAW,
        DYNAMIC_READ = GL_DYNAMIC_READ,
        DYNAMIC_COPY = GL_DYNAMIC_COPY
    }

    enum Access
    {
        READ_ONLY  = GL_READ_ONLY,
        WRITE_ONLY = GL_WRITE_ONLY,
        READ_WRITE = GL_READ_WRITE
    }

    enum Target
    {
        ARRAY_BUFFER              = GL_ARRAY_BUFFER,
        ATOMIC_COUNTER_BUFFER     = GL_ATOMIC_COUNTER_BUFFER,
        COPY_READ_BUFFER          = GL_COPY_READ_BUFFER,
        COPY_WRITE_BUFFER         = GL_COPY_WRITE_BUFFER,
        DRAW_INDIRECT_BUFFER      = GL_DRAW_INDIRECT_BUFFER,
        DISPATCH_INDIRECT_BUFFER  = GL_DISPATCH_INDIRECT_BUFFER,
        ELEMENT_ARRAY_BUFFER      = GL_ELEMENT_ARRAY_BUFFER,
        PIXEL_PACK_BUFFER         = GL_PIXEL_PACK_BUFFER,
        PIXEL_UNPACK_BUFFER       = GL_PIXEL_UNPACK_BUFFER,
        SHADER_STORAGE_BUFFER     = GL_SHADER_STORAGE_BUFFER,
        TEXTURE_BUFFER            = GL_TEXTURE_BUFFER,
        TRANSFORM_FEEDBACK_BUFFER = GL_TRANSFORM_FEEDBACK_BUFFER,
        UNIFORM_BUFFER            = GL_UNIFORM_BUFFER
    }

    static nothrow void unbind( Target trg )
    { glBindBuffer( cast(GLenum)trg, 0 ); }

    this( Target tp=Target.ARRAY_BUFFER )
    {
        checkGLCall!glGenBuffers( 1, &_id );
        type = tp;

        logger = new InstanceLogger( this, format( "%d", _id ) );

        logger.Debug( "with type [%s]", type );
    }

    final
    {
        void bind()
        {
            checkGLCall!glBindBuffer( gltype, _id );
            debug logger.trace( "with type [%s]", type );
        }
        void unbind()
        {
            checkGLCall!glBindBuffer( gltype, 0 );
            debug logger.trace( "type [%s]", type );
        }
        @property uint id() const { return _id; }
    }

    void delegate(size_t) elementCountCallback;
    void delegate(size_t) dataSizeCallback;
    void delegate(size_t) elementSizeCallback;

    void setUntypedData( in void[] data_arr, size_t element_size, Usage mem=Usage.DYNAMIC_DRAW )
    {
        auto size = data_arr.length;
        if( !size ) throw new GLObjException( "set buffer data size is 0" );

        bind();
        checkGLCall!glBufferData( gltype, size, data_arr.ptr, cast(GLenum)mem );
        unbind();

        element_count = data_arr.length / element_size;
        data_size = size;

        if( elementCountCallback !is null )
            elementCountCallback( element_count );

        if( dataSizeCallback !is null )
            dataSizeCallback( data_size );

        if( elementSizeCallback !is null )
            elementSizeCallback( element_size );

        debug logger.trace( "[%d] [%s]: size [%d], element size [%d], usage [%s]",
                type, size, element_size, mem );
    }

    void setSubUntypedData( size_t offset, in void[] data_arr, size_t element_size )
    {
        auto size = data_arr.length;

        if( !size ) throw new GLObjException( "set sub buffer data size is 0" );
        if( offset + size > data_size )
            throw new GLObjException( "set sub buffer data: offset+size > data_size" );

        bind();
        checkGLCall!glBufferSubData( gltype, offset, size, data_arr.ptr );
        unbind();

        debug logger.trace( "[%s]: offset [%d], size [%d], element size [%d]",
                type, offset, size, element_size );
    }

    void[] getUntypedData()
    {
        bind();
        auto mp = map( Access.READ_ONLY );
        auto buf = new void[]( data_size );
        memcpy( buf.ptr, mp, data_size );
        unmap();
        unbind();
        return buf;
    }

    void[] getSubUntypedData( size_t offset, size_t length )
    {
        bind();
        auto mp = mapRange( offset, length, Access.READ_ONLY );
        auto buf = new void[]( length );
        memcpy( buf.ptr, mp, length );
        unmap();
        unbind();
        return buf;
    }

    void setData(E)( in E[] data_arr, Usage mem=Usage.DYNAMIC_DRAW )
    { setUntypedData( data_arr, E.sizeof, mem ); }

    void setSubData(E)( size_t offset, in E[] data_arr )
    { setSubUntypedData( offset * E.sizeof, data_arr, E.sizeof ); }

    E[] getData(E)() { return cast(E[])getUntypedData(); }

    E[] getSubData(E)( size_t offset, size_t count )
    { return cast(E[])getSubUntypedData( E.sizeof * offset, E.sizeof * count ); }

    @property
    {
        const final
        {
            size_t elementCount() { return element_count; }
            size_t dataSize() { return data_size; }

            size_t elementSize()
            { return element_count ? data_size / element_count : 0; }
        }
    }

    void* map( Access access=Access.READ_ONLY )
    {
        debug logger.trace( "by access [%s]", access );
        return checkGLCall!glMapBuffer( gltype, cast(GLenum)access );
    }

    void* mapRange( size_t offset, size_t length, Access access=Access.READ_ONLY )
    { 
        if( offset + length > data_size )
            throw new GLObjException( "map buffer range: offset + length > data_size" );
        debug logger.trace( "by access [%s]: offset [%d], length [%d]", access, offset, length );
        return checkGLCall!glMapBufferRange( gltype, offset, length, cast(GLenum)access );
    }

    void unmap()
    {
        checkGLCall!glUnmapBuffer( gltype );
        debug logger.trace( "pass" );
    }

protected:

    void selfDestroy()
    {
        checkGLCall!glDeleteBuffers( 1, &_id );
        debug logger.Debug( "pass" );
    }
}

final class GLVAO : ExternalMemoryManager
{
    mixin DirectEMM;
    mixin ClassLogger;

protected:
    uint _id;

    void selfDestroy() { glDeleteVertexArrays( 1, &_id ); }

public:
    static nothrow void unbind(){ glBindVertexArray(0); }

    this()
    {
        checkGLCall!glGenVertexArrays( 1, &_id );
        logger = new InstanceLogger( this, format( "%d", _id ) );
        logger.Debug( "pass" );
    }

    nothrow 
    {
        void bind() 
        { 
            ntCheckGLCall!glBindVertexArray( _id );
            debug logger.trace( "pass" );
        }

        void enable( int n )
        {
            debug scope(exit) logger.Debug( "[%d]", n );
            if( n < 0 ) return;
            bind();
            ntCheckGLCall!glEnableVertexAttribArray( n ); 
        }

        void disable( int n )
        {
            debug scope(exit) logger.Debug( "[%d]", n );
            if( n < 0 ) return;
            bind();
            ntCheckGLCall!glDisableVertexAttribArray( n ); 
        }
    }
}

class GLObject: ExternalMemoryManager
{
    mixin ParentEMM;
    mixin ClassLogger;

protected:
    GLVAO vao;

    final
    {
        void setAttribPointer( GLBuffer buffer, int index, uint per_element,
                GLType attype, bool norm=false )
        { setAttribPointer( buffer, index, per_element, attype, 0, 0, norm ); }

        void setAttribPointer( GLBuffer buffer, int index, uint per_element,
                GLType attype, size_t stride, size_t offset, bool norm=false )
        {
            vao.enable( index );

            buffer.bind();
            checkGLCall!glVertexAttribPointer( index, cast(int)per_element,
                    cast(GLenum)attype, norm, cast(int)stride, cast(void*)offset );
            buffer.unbind();

            logger.Debug( "VAO [%d], buffer [%d], "~
                            "index [%d], per element [%d][%s]"~
                            "%s%s",
                            vao._id, buffer.id,
                            index, per_element, attype, 
                            stride != 0 ? toMessage(", stride [%d], offset [%d]", stride, offset ) : "",
                            norm ? toMessage( ", norm [%s]", norm ) : "" );
        }
    }

public:

    this()
    {
        vao = newEMM!GLVAO;
        debug checkGL;
    }
}
