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

import des.gl.base.texture;
import des.gl.base.type;

import des.il.image;

///
class GLFBOException : DesGLException 
{ 
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

///
class GLRenderBuffer : DesObject
{
    mixin DES;
    mixin ClassLogger;

protected:
    uint _id;
    Format _format;

public:

    ///
    enum Format
    {
        R8                 = GL_R8,                 /// `GL_R8`
        R8UI               = GL_R8UI,               /// `GL_R8UI`
        R8I                = GL_R8I,                /// `GL_R8I`
        R16UI              = GL_R16UI,              /// `GL_R16UI`
        R16I               = GL_R16I,               /// `GL_R16I`
        R32UI              = GL_R32UI,              /// `GL_R32UI`
        R32I               = GL_R32I,               /// `GL_R32I`
        RG8                = GL_RG8,                /// `GL_RG8`
        RG8UI              = GL_RG8UI,              /// `GL_RG8UI`
        RG8I               = GL_RG8I,               /// `GL_RG8I`
        RG16UI             = GL_RG16UI,             /// `GL_RG16UI`
        RG16I              = GL_RG16I,              /// `GL_RG16I`
        RG32UI             = GL_RG32UI,             /// `GL_RG32UI`
        RG32I              = GL_RG32I,              /// `GL_RG32I`
        RGB8               = GL_RGB8,               /// `GL_RGB8`
        RGBA8              = GL_RGBA8,              /// `GL_RGBA8`
        SRGB8_ALPHA8       = GL_SRGB8_ALPHA8,       /// `GL_SRGB8_ALPHA8`
        RGB5_A1            = GL_RGB5_A1,            /// `GL_RGB5_A1`
        RGBA4              = GL_RGBA4,              /// `GL_RGBA4`
        RGB10_A2           = GL_RGB10_A2,           /// `GL_RGB10_A2`
        RGBA8UI            = GL_RGBA8UI,            /// `GL_RGBA8UI`
        RGBA8I             = GL_RGBA8I,             /// `GL_RGBA8I`
        RGB10_A2UI         = GL_RGB10_A2UI,         /// `GL_RGB10_A2UI`
        RGBA16UI           = GL_RGBA16UI,           /// `GL_RGBA16UI`
        RGBA16I            = GL_RGBA16I,            /// `GL_RGBA16I`
        RGBA32I            = GL_RGBA32I,            /// `GL_RGBA32I`
        RGBA32UI           = GL_RGBA32UI,           /// `GL_RGBA32UI`
        DEPTH_COMPONENT16  = GL_DEPTH_COMPONENT16,  /// `GL_DEPTH_COMPONENT16`
        DEPTH_COMPONENT24  = GL_DEPTH_COMPONENT24,  /// `GL_DEPTH_COMPONENT24`
        DEPTH_COMPONENT32F = GL_DEPTH_COMPONENT32F, /// `GL_DEPTH_COMPONENT32F`
        DEPTH24_STENCIL8   = GL_DEPTH24_STENCIL8,   /// `GL_DEPTH24_STENCIL8`
        DEPTH32F_STENCIL8  = GL_DEPTH32F_STENCIL8,  /// `GL_DEPTH32F_STENCIL8`
        STENCIL_INDEX8     = GL_STENCIL_INDEX8      /// `GL_STENCIL_INDEX8`
    }

    /// glGenRenderbuffers
    this()
    {
        checkGLCall!glGenRenderbuffers( 1, &_id );
        logger = new InstanceLogger( this, std.string.format( "%d", _id ) );
        logger.Debug( "pass" );
    }

    final pure const @property
    {
        ///
        uint id() { return _id; }

        ///
        Format format() { return _format; }
    }

    /// `glBindRenderbuffer( GL_RENDERBUFFER, id )`
    void bind()
    {
        checkGLCall!glBindRenderbuffer( GL_RENDERBUFFER, _id );
        debug logger.trace( "[%d]", id );
    }

    /// `glBindRenderbuffer( GL_RENDERBUFFER, 0 )`
    void unbind()
    {
        checkGLCall!glBindRenderbuffer( GL_RENDERBUFFER, 0 );
        debug logger.trace( "call from [%d]", _id );
    }

    /// glRenderbufferStorage
    void storage( in uivec2 sz, Format fmt )
    in
    {
        assert( sz[0] < GL_MAX_RENDERBUFFER_SIZE );
        assert( sz[1] < GL_MAX_RENDERBUFFER_SIZE );
    }
    body
    {
        bind();
        _format = fmt;
        checkGLCall!glRenderbufferStorage( GL_RENDERBUFFER, cast(GLenum)fmt, sz[0], sz[1] );
        unbind();
        debug logger.Debug( "size [%d,%d], format [%s]", sz[0], sz[1], fmt );
    }

    /// ditto
    void storage(T)( in Vector!(2,T) sz, Format fmt )
    if( isIntegral!T )
    in
    {
        assert( sz[0] >= 0 );
        assert( sz[1] >= 0 );
    }
    body { storage( uivec2(sz), fmt ); }

    /// set storage with new size and old format
    void resize( in uivec2 sz ) { storage( sz, _format ); }

    /// ditto
    void resize(T)( in Vector!(2,T) sz )
    if( isIntegral!T )
    { resize( uivec2(sz) ); }

protected:

    override void selfDestroy()
    {
        unbind();
        checkGLCall!glDeleteRenderbuffers( 1, &_id );
        logger.Debug( "pass" );
    }
}

///
class GLFrameBuffer : DesObject
{
    mixin DES;
    mixin ClassLogger;

protected:
    uint _id;
    static uint[] id_stack;

public:

    // TODO: not work with gl constant
    //mixin( getAttachmentEnumString!GL_MAX_COLOR_ATTACHMENTS );
    mixin( getAttachmentEnumString!1 );

    /// glGenFramebuffers
    this()
    {
        if( id_stack.length == 0 ) id_stack ~= 0;

        checkGLCall!glGenFramebuffers( 1, &_id );
        logger = new InstanceLogger( this, format( "%d", _id ) );
        logger.Debug( "pass" );
    }

    final pure const @property
    {
        ///
        uint id() { return _id; }
    }

    final nothrow
    {
        /// glBindFramebuffer add id to stack 
        void bind()
        {
            if( id_stack[$-1] == _id ) return;
            ntCheckGLCall!glBindFramebuffer( GL_FRAMEBUFFER, _id );
            id_stack ~= _id;
            debug logger.trace( "pass" );
        }

        /// pop from stack old frame buffer id and glBindFramebuffer with it
        void unbind()
        {
            if( id_stack.length < 2 && id_stack[$-1] != _id ) return;
            id_stack.length--;
            ntCheckGLCall!glBindFramebuffer( GL_FRAMEBUFFER, id_stack[$-1] );
            debug logger.trace( "bind [%d]", _id, id_stack[$-1] );
        }
    }

    ///
    void setAttachment(T)( T obj, Attachment att )
        if( is( T : GLTexture ) || is( T : GLRenderBuffer ) )
    {
        static if( is( T : GLTexture ) )
            texture( obj, att );
        else static if( is( T : GLRenderBuffer ) )
            renderBuffer( obj, att );
    }

    /// set texture attachment
    void texture( GLTexture tex, Attachment att )
    in { assert( isValidTextureTarget(tex.target) ); }
    body { texture( tex, att, tex.target ); }

    /// ditto
    void texture( GLTexture tex, Attachment att, GLTexture.Target trg )
    in { assert( isValidTextureTarget(trg) ); } body
    {
        bind(); scope(exit) unbind();

        if( trg == tex.Target.T1D )
            checkGLCall!glFramebufferTexture1D( GL_FRAMEBUFFER, cast(GLenum)att,
                                        cast(GLenum)trg, tex.id, 0 );
        else if( tex.target == tex.Target.T3D )
            checkGLCall!glFramebufferTexture3D( GL_FRAMEBUFFER, cast(GLenum)att,
                                    cast(GLenum)trg, tex.id, 0, 0 );
        else
            checkGLCall!glFramebufferTexture2D( GL_FRAMEBUFFER, cast(GLenum)att,
                                    cast(GLenum)trg, tex.id, 0 );

        logger.Debug( "[%s] as [%s]", tex.id, att );
    }

    /// set render buffer attachment
    void renderBuffer( GLRenderBuffer rbo, Attachment att )
    {
        bind(); scope(exit) unbind();

        checkGLCall!glFramebufferRenderbuffer( GL_FRAMEBUFFER, cast(GLenum)att, 
                                   GL_RENDERBUFFER, rbo.id );

        logger.Debug( "[%d] as [%s]", rbo.id, att );
    }

    /// glCheckFramebufferStatus
    void check()
    {
        bind(); scope(exit) unbind();
        auto status = checkGLCall!glCheckFramebufferStatus( GL_FRAMEBUFFER );
        import std.string;
        if( status != GL_FRAMEBUFFER_COMPLETE )
            throw new GLFBOException( format( "status isn't GL_FRAMEBUFFER_COMPLETE, it's %#x", status ) );
    }

protected:
    override void selfDestroy()
    {
        unbind();
        checkGLCall!glDeleteFramebuffers( 1, &_id );
        logger.Debug( "pass" );
    }

    static string getAttachmentEnumString(size_t COLOR_ATTACHMENT_COUNT)() @property
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
