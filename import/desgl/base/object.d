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

import derelict.opengl3.gl3;

import desgl.util.ext;

import desutil.logger;
mixin( PrivateLoggerMixin );

class GLObjException : DesGLException 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

class GLVBO : ExternalMemoryManager
{
protected:
    uint vboID;
    GLenum type;
public:
    static nothrow void unbind( GLenum tp ){ glBindBuffer( tp, 0 ); }

    this(E=float)( in E[] data_arr=[], GLenum Type=GL_ARRAY_BUFFER, GLenum mem=GL_DYNAMIC_DRAW )
    {
        glGenBuffers( 1, &vboID );
        type = Type;
        if( data_arr !is null && data_arr.length ) setData( data_arr, mem );

        debug checkGL;
    }

    final
    {
        nothrow
        {
            void bind() { glBindBuffer( type, vboID ); }
            void unbind(){ glBindBuffer( type, 0 ); }
            @property uint id() const { return vboID; }
        }
        
        void setData(E)( in E[] data_arr, GLenum mem=GL_DYNAMIC_DRAW )
        {
            auto size = E.sizeof * data_arr.length;
            if( !size ) throw new GLObjException( "buffer data size is 0" );

            glBindBuffer( type, vboID );
            glBufferData( type, size, data_arr.ptr, mem );
            glBindBuffer( type, 0 );

            debug checkGL;
            debug log( "vbo setData (%d byte)", size );
        }
    }

    void destroy() { glDeleteBuffers( 1, &vboID ); }
}

final class GLVAO : ExternalMemoryManager
{
protected:
    uint vaoID;

public:
    static nothrow void unbind(){ glBindVertexArray(0); }

    this() { glGenVertexArrays( 1, &vaoID ); }

    nothrow 
    {
        void bind() 
        { 
            glBindVertexArray( vaoID ); 
            debug log( "bind:  %d", vaoID );
            debug checkGL;
        }

        void enable( int n )
        { 
            bind();
            glEnableVertexAttribArray( n ); 
            debug log_info( "enable attrib %d for vao %d", n, vaoID );
            debug checkGL;
        }

        void disable( int n )
        { 
            bind();
            glDisableVertexAttribArray( n ); 
            debug log_info( "disable attrib %d for vao %d", n, vaoID );
            debug checkGL;
        }
    }

    void destroy() { glDeleteVertexArrays( 1, &vaoID ); }
}

class GLObj: ExternalMemoryManager
{
protected:
    ExternalMemoryManager[] childEMM;

    GLVAO vao;

    final nothrow
    {
        void setAttribPointer( GLVBO buffer, int index, uint size, GLenum attype, bool norm=false )
        { setAttribPointer( buffer, index, size, attype, 0, 0, norm ); }

        void setAttribPointer( GLVBO buffer, int index, uint size, 
                GLenum attype, size_t stride, size_t offset, bool norm=false )
        {
            vao.bind();
            vao.enable( index );

            buffer.bind();
            glVertexAttribPointer( index, cast(int)size, attype, norm, 
                    cast(int)stride, cast(void*)offset );
            buffer.unbind();
        }
    }

public:

    this()
    {
        vao = new GLVAO;
        childEMM ~= vao;
        debug checkGL;
    }

    void destroy()
    { 
        foreach( emm; childEMM )
            emm.destroy();
    }
}
