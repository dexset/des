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

module des.gl.base.frame;

import derelict.opengl3.gl3;

import des.math.linear;
import des.util.emm;

import des.gl.base.texture;
import des.gl.util;

import des.util.logger;
mixin( PrivateLoggerMixin );

import des.il.image;

class GLFBOException : DesGLException 
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); } 
}

class GLRenderBuffer : ExternalMemoryManager
{
mixin( getMixinChildEMM );
protected:
    uint _id;
    Format _format;
public:

    enum Format
    {
        R8                 = GL_R8,
        R8UI               = GL_R8UI,
        R8I                = GL_R8I,
        R16UI              = GL_R16UI,
        R16I               = GL_R16I,
        R32UI              = GL_R32UI,
        R32I               = GL_R32I,
        RG8                = GL_RG8,
        RG8UI              = GL_RG8UI,
        RG8I               = GL_RG8I,
        RG16UI             = GL_RG16UI,
        RG16I              = GL_RG16I,
        RG32UI             = GL_RG32UI,
        RG32I              = GL_RG32I,
        RGB8               = GL_RGB8,
        RGBA8              = GL_RGBA8,
        SRGB8_ALPHA8       = GL_SRGB8_ALPHA8,
        RGB5_A1            = GL_RGB5_A1,
        RGBA4              = GL_RGBA4,
        RGB10_A2           = GL_RGB10_A2,
        RGBA8UI            = GL_RGBA8UI,
        RGBA8I             = GL_RGBA8I,
        RGB10_A2UI         = GL_RGB10_A2UI,
        RGBA16UI           = GL_RGBA16UI,
        RGBA16I            = GL_RGBA16I,
        RGBA32I            = GL_RGBA32I,
        RGBA32UI           = GL_RGBA32UI,
        DEPTH_COMPONENT16  = GL_DEPTH_COMPONENT16,
        DEPTH_COMPONENT24  = GL_DEPTH_COMPONENT24,
        DEPTH_COMPONENT32F = GL_DEPTH_COMPONENT32F,
        DEPTH24_STENCIL8   = GL_DEPTH24_STENCIL8,
        DEPTH32F_STENCIL8  = GL_DEPTH32F_STENCIL8,
        STENCIL_INDEX8     = GL_STENCIL_INDEX8
    }

    @property Format format() { return _format; }

    this()
    {
        glGenRenderbuffers( 1, &_id );
        debug checkGL;
    }

    final pure const @property uint id() { return _id; }

    void bind() { glBindRenderbuffer( GL_RENDERBUFFER, _id ); }
    void unbind() { glBindRenderbuffer( GL_RENDERBUFFER, 0 ); }

    void storage(T)( in T sz, Format fmt )
    if( isCompatibleVector!(2,uint,T) )
    in
    {
        assert( sz[0] < GL_MAX_RENDERBUFFER_SIZE );
        assert( sz[0] >= 0 );
        assert( sz[1] < GL_MAX_RENDERBUFFER_SIZE );
        assert( sz[1] >= 0 );
    }
    body
    {
        bind(); scope(exit) unbind();
        _format = fmt;
        glRenderbufferStorage( GL_RENDERBUFFER, cast(GLenum)fmt, sz[0], sz[1] );
        debug checkGL;
        unbind();
    }

    void resize(T)( in T sz )
    if( isCompatibleVector!(2,uint,T) )
    { storage( sz, _format ); }

protected:
    void selfDestroy()
    {
        unbind();
        glDeleteRenderbuffers( 1, &_id );
    }
}

class GLFrameBuffer : ExternalMemoryManager
{
mixin( getMixinChildEMM );
protected:
    uint _id;
    static uint[] id_stack;

public:

    // TODO: not work with gl constant
    //mixin( getAttachmentEnumString!GL_MAX_COLOR_ATTACHMENTS );
    mixin( getAttachmentEnumString!1 );

    this()
    {
        if( id_stack.length == 0 ) id_stack ~= 0;

        glGenFramebuffers( 1, &_id );
        debug checkGL;
    }

    final pure const @property uint id() { return _id; }

    final nothrow
    {
        void bind()
        {
            if( id_stack[$-1] == _id ) return;
            glBindFramebuffer( GL_FRAMEBUFFER, _id );
            id_stack ~= _id;
        }

        void unbind()
        {
            if( id_stack.length < 2 && id_stack[$-1] != _id ) return;
            id_stack.length--;
            glBindFramebuffer( GL_FRAMEBUFFER, id_stack[$-1] );
        }
    }

    void setAttachment(T)( T obj, Attachment attachment )
        if( is( T : GLTexture ) || is( T : GLRenderBuffer ) )
    {
        static if( is( T : GLTexture ) )
            texture( obj, attachment );
        else static if( is( T : GLRenderBuffer ) )
            renderBuffer( obj, attachment );
    }

    void texture( GLTexture tex, Attachment attachment )
    in { assert( isValidTextureTarget(tex.target) ); }
    body { texture( tex, attachment, tex.target ); }

    void texture( GLTexture tex, Attachment attachment, GLTexture.Target trg )
    in { assert( isValidTextureTarget(trg) ); } body
    {
        bind(); scope(exit) unbind();

        if( trg == tex.Target.T1D )
            glFramebufferTexture1D( GL_FRAMEBUFFER, cast(GLenum)attachment,
                                    cast(GLenum)trg, tex.id, 0 );
        else if( tex.target == tex.Target.T3D )
            glFramebufferTexture3D( GL_FRAMEBUFFER, cast(GLenum)attachment,
                                    cast(GLenum)trg, tex.id, 0, 0 );
        else
            glFramebufferTexture2D( GL_FRAMEBUFFER, cast(GLenum)attachment,
                                    cast(GLenum)trg, tex.id, 0 );

        debug checkGL;
    }

    void renderBuffer( GLRenderBuffer rbo, Attachment attachment )
    {
        bind(); scope(exit) unbind();

        glFramebufferRenderbuffer( GL_FRAMEBUFFER, cast(GLenum)attachment, 
                                   GL_RENDERBUFFER, rbo.id );

        debug checkGL;
    }

    void check()
    {
        bind(); scope(exit) unbind();
        auto status = glCheckFramebufferStatus( GL_FRAMEBUFFER );
        import std.string;
        if( status != GL_FRAMEBUFFER_COMPLETE )
            throw new GLFBOException( format( "status isn't GL_FRAMEBUFFER_COMPLETE, it's %#x", status ) );
        debug checkGL;
    }

protected:
    void selfDestroy()
    {
        unbind();
        glDeleteFramebuffers( 1, &_id );
    }

    @property static string getAttachmentEnumString(size_t COLOR_ATTACHMENT_COUNT)()
    {
        import std.string;
        string[] ret;

        ret ~= `
        enum Attachment
        {
            `;

        foreach( i; 0 .. COLOR_ATTACHMENT_COUNT )
            ret ~= format( "COLOR%1d = GL_COLOR_ATTACHMENT%1d,", i, i );

        ret ~= "DEPTH         = GL_DEPTH_ATTACHMENT,";
        ret ~= "STENCIL       = GL_STENCIL_ATTACHMENT,";
        ret ~= "DEPTH_STENCIL = GL_DEPTH_STENCIL_ATTACHMENT,";

        ret ~= `}`;

        return ret.join("\n");
    }

    bool isValidTextureTarget( GLTexture.Target trg )
    {
        switch(trg)
        {
        case GLTexture.Target.T1D:
        case GLTexture.Target.T2D:
        case GLTexture.Target.RECTANGLE:
        case GLTexture.Target.T3D:
        case GLTexture.Target.CUBE_MAP_POSITIVE_X:
        case GLTexture.Target.CUBE_MAP_NEGATIVE_X:
        case GLTexture.Target.CUBE_MAP_POSITIVE_Y:
        case GLTexture.Target.CUBE_MAP_NEGATIVE_Y:
        case GLTexture.Target.CUBE_MAP_POSITIVE_Z:
        case GLTexture.Target.CUBE_MAP_NEGATIVE_Z:
            return true;
        default: return false;
        }
    }
}

