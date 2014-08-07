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

module desgl.base.object;

import std.c.string;

import derelict.opengl3.gl3;

import desgl.util.ext;
import desgl.base.type;

import desutil;
mixin( PrivateLoggerMixin );

class GLObjException : DesGLException 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

class GLBuffer : ExternalMemoryManager
{
mixin( getMixinChildEMM );
protected:
    uint _id;
    Target type;

    size_t data_size;
    size_t element_count;

    void selfDestroy() { glDeleteBuffers( 1, &_id ); }

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
        glGenBuffers( 1, &_id );
        type = tp;

        debug checkGL;
    }

    final
    {
        nothrow
        {
            void bind() { glBindBuffer( gltype, _id ); }
            void unbind(){ glBindBuffer( gltype, 0 ); }
            @property uint id() const { return _id; }
        }
        
        void setData(E)( in E[] data_arr, Usage mem=Usage.DYNAMIC_DRAW )
        {
            auto size = E.sizeof * data_arr.length;
            if( !size ) throw new GLObjException( "buffer data size is 0" );

            bind();
            glBufferData( gltype, size, data_arr.ptr, cast(GLenum)mem );
            unbind();

            element_count = data_arr.length;
            data_size = size;

            debug checkGL;
        }

        E[] getData(E)() { return cast(E[])getUntypedData(); }

        void[] getUntypedData()
        {
            auto buf = new void[]( data_size );
            bind();
            auto mp = map( Access.READ_ONLY );
            memcpy( buf.ptr, mp, data_size );
            unmap();
            unbind();
            return buf;
        }

        @property
        {
            const
            {
                size_t elementCount() { return element_count; }
                size_t dataSize() { return data_size; }

                size_t elementSize()
                { return element_count ? data_size / element_count : 0; }
            }
        }

        void* map( Access access=Access.READ_ONLY )
        {
            debug scope(exit) checkGL;
            return glMapBuffer( gltype, cast(GLenum)access );
        }

        void unmap() { glUnmapBuffer( gltype ); }
    }
}

final class GLVAO : ExternalMemoryManager
{
    mixin( getMixinChildEMM );

protected:
    uint _id;

    void selfDestroy() { glDeleteVertexArrays( 1, &_id ); }

public:
    static nothrow void unbind(){ glBindVertexArray(0); }

    this() { glGenVertexArrays( 1, &_id ); }

    nothrow 
    {
        void bind() 
        { 
            glBindVertexArray( _id ); 
            debug(glvao) log( "bind:  %d", _id );
            debug checkGL;
        }

        void enable( int n )
        {
            debug log_info( "enable attrib %d for vao %d", n, _id );
            if( n < 0 ) return;
            bind();
            glEnableVertexAttribArray( n ); 
            debug checkGL;
        }

        void disable( int n )
        {
            debug log_info( "disable attrib %d for vao %d", n, _id );
            if( n < 0 ) return;
            bind();
            glDisableVertexAttribArray( n ); 
            debug checkGL;
        }
    }
}

class GLObj: ExternalMemoryManager
{
    mixin( getMixinAllEMMFuncs );

protected:
    GLVAO vao;

    final nothrow
    {
        void setAttribPointer( GLBuffer buffer, int index, uint per_element, 
                GLType attype, bool norm=false )
        { setAttribPointer( buffer, index, per_element, attype, 0, 0, norm ); }

        void setAttribPointer( GLBuffer buffer, int index, uint per_element, 
                GLType attype, size_t stride, size_t offset, bool norm=false )
        {
            vao.bind();
            vao.enable( index );

            buffer.bind();
            glVertexAttribPointer( index, cast(int)per_element,
                    cast(GLenum)attype, norm, cast(int)stride, cast(void*)offset );
            buffer.unbind();
        }
    }

public:

    this()
    {
        vao = registerChildEMM( new GLVAO );
        debug checkGL;
    }
}
