module des.gl.base.rbo;

import std.exception;
import std.conv;

import derelict.opengl3.gl3;

import des.math.linear;

import des.gl.base.type;

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

    /// `glGenRenderbuffers`
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

    /// `glRenderbufferStorage`
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
        assert( sz[0] > 0 );
        assert( sz[1] > 0 );
    }
    body { storage( uivec2(sz), fmt ); }

    /// set storage with new size and old format
    void resize( in uivec2 sz )
    in
    {
        assert( sz[0] > 0 );
        assert( sz[1] > 0 );
    }
    body { storage( sz, _format ); }

    /// ditto
    void resize(T)( in Vector!(2,T) sz )
    if( isIntegral!T )
    in
    {
        assert( sz[0] > 0 );
        assert( sz[1] > 0 );
    }
    body { resize( uivec2(sz) ); }

protected:

    override void selfDestroy()
    {
        unbind();
        checkGLCall!glDeleteRenderbuffers( 1, &_id );
        logger.Debug( "pass" );
    }
}