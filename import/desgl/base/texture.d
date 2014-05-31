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

module desgl.base.texture;

public import derelict.opengl3.gl3;

import desgl.util.ext;

import desmath.linear.vector;
import desil;

class TextureException : DesGLException 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

private @property string accessVecFields(T,string name)()
    if( isVector!T )
{
    import std.string : format;
    string ret;
    foreach( i; 0 .. T.length )
        ret ~= format( "cast(int)(%s[%d]),", name, i );
    return ret[0 .. $-1];
}

class GLTexture(ubyte DIM) if( DIM == 1 || DIM == 2 || DIM == 3 ) : ExternalMemoryManager
{
    mixin( getMixinChildEMM );

    import std.string : format;

    private uint texID;
    @property pure uint id() const { return texID; }
    protected texsize_t sz;

    mixin( format( "enum GLenum type = GL_TEXTURE_%1dD;", DIM ) );
    alias vec!(DIM,long,"whd"[0 .. DIM]) texsize_t; 

    this()
    {
        glGenTextures( 1, &texID );
        debug checkGL;
        bind(); scope(exit) unbind();
        debug checkGL;

        parameteri( GL_TEXTURE_MAG_FILTER, GL_LINEAR );
        parameteri( GL_TEXTURE_MIN_FILTER, GL_LINEAR );

        debug checkGL;
    }

    void genMipmap()
    {
        bind();
        glGenerateMipmap(type);
    }

    /+ TODO
        разных функций ярких и много!
     +/
    final void parameteri( GLenum param, int val )
    { 
        bind();
        glTexParameteri( type, param, val ); 
    }

    final void parameterf( GLenum param, float val )
    { 
        bind();
        glTexParameterf( type, param, val ); 
    }

    final nothrow void bind() { glBindTexture( type, texID ); }
    static nothrow void unbind() { glBindTexture( type, 0 ); }

    final @property texsize_t size() const { return sz; }

    final void image(T,E=ubyte)( in T nsz, int texfmt, GLenum datafmt, GLenum datatype, in E* data=null )
        if( isCompVector!(DIM,long,T) )
    {
        sz = nsz;
        bind();
        mixin( format( "glTexImage%1dD( type, 0, texfmt, %s, 0, datafmt, datatype, cast(void*)data );",
                    DIM, accessVecFields!(T,"sz") ) );
        debug checkGL;
    }

    static if( DIM == 2 )
    {
        final void getImage( ref Image img, uint level=0, GLenum fmt=GL_RGB, GLenum rtype=GL_UNSIGNED_BYTE )
        {
            bind();
            if( level ) glGenerateMipmap(GL_TEXTURE_2D);
            debug checkGL;
            int w, h;
            glGetTexLevelParameteriv( GL_TEXTURE_2D, level, GL_TEXTURE_WIDTH, &(w));
            debug checkGL;
            glGetTexLevelParameteriv( GL_TEXTURE_2D, level, GL_TEXTURE_HEIGHT, &(h));
            debug checkGL;

            import std.string;
            size_t elemSize = 1;
            switch(fmt)
            {
                case GL_RED: case GL_GREEN: case GL_BLUE: break;
                case GL_RG: elemSize *= 2; break;
                case GL_RGB: case GL_BGR: elemSize *= 3; break;
                case GL_RGBA: case GL_BGRA: elemSize *= 4; break;
                default: throw new TextureException( format( "getImage not support format %s", fmt ) );
            }

            switch(rtype)
            {
                case GL_UNSIGNED_BYTE: case GL_BYTE: break;
                case GL_UNSIGNED_SHORT: case GL_SHORT: elemSize *= short.sizeof; break;
                case GL_UNSIGNED_INT: case GL_INT: elemSize *= int.sizeof; break;
                case GL_FLOAT: elemSize *= float.sizeof; break;
                default: throw new TextureException( format( "getImage not support type %s", rtype ) );
            }

            auto dsize = w * h * elemSize;

            if( img.size != imsize_t(w,h) || img.type.bpp != elemSize )
                img.allocate( imsize_t(w,h), ImageType( elemSize ) );

            glGetTexImage( GL_TEXTURE_2D, level, fmt, rtype, img.data.ptr );
            debug checkGL;
            unbind();
            debug checkGL;
        }

        final void image( in Image img )
        {
            GLenum fmt, type;
            switch( img.type.comp )
            {
                case ImCompType.RAWBYTE: case ImCompType.UBYTE:
                    type = GL_UNSIGNED_BYTE; break;
                case ImCompType.FLOAT: case ImCompType.NORM_FLOAT:
                    type = GL_FLOAT; break;
                default:
                    throw new TextureException( "uncompatible image component type" );
            }
            switch( img.type.channels )
            {
                case 1: fmt = GL_RED;  break;
                case 2: fmt = GL_RG;   break;
                case 3: fmt = GL_RGB;  break;
                case 4: fmt = GL_RGBA; break;
                default:
                    throw new TextureException( "uncompatible image chanels count" );
            }
            image( img.size, cast(int)img.type.channels, 
                   fmt, type, img.data.ptr );
        }

        final void image( in ImageReadAccess ira )
        { 
            if( ira !is null ) image( ira.selfImage() ); 
            else image( ivec2(1,1), 3, GL_RGB, GL_UNSIGNED_BYTE );
        }
    }

    protected void selfDestroy()
    {
        unbind();
        glDeleteTextures( 1, &texID );

        debug checkGL;
    }
}

alias GLTexture!2 GLTexture2D;
