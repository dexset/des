module des.gl.base.frame;

import std.exception;
import std.conv;

import des.gl.base.general;
import des.gl.base.texture;
import des.gl.base.rbo;

///
class GLFBOException : DesGLException
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

///
class GLFrameBuffer : GLObject!"Framebuffer"
{
    mixin DES;
    mixin ClassLogger;

protected:
    static uint[] id_stack;

    ///
    enum Attachment
    {
        COLOR         = GL_COLOR_ATTACHMENT0,        /// `GL_COLOR_ATTACHMENT0`
        DEPTH         = GL_DEPTH_ATTACHMENT,         /// `GL_DEPTH_ATTACHMENT`
        STENCIL       = GL_STENCIL_ATTACHMENT,       /// `GL_STENCIL_ATTACHMENT`
        DEPTH_STENCIL = GL_DEPTH_STENCIL_ATTACHMENT, /// `GL_DEPTH_STENCIL_ATTACHMENT`
    }

public:

    ///
    this()
    {
        if( id_stack.length == 0 ) id_stack ~= 0;
        super( GL_FRAMEBUFFER );
        logger.Debug( "pass" );
    }

    final
    {
        /// `glBindFramebuffer` add id to stack
        override void bind()
        {
            if( id_stack[$-1] == id ) return;
            ntCheckGLCall!glBindFramebuffer( GL_FRAMEBUFFER, id );
            id_stack ~= id;
            debug logger.trace( "pass" );
        }

        /// pop from stack old frame buffer id and `glBindFramebuffer` with it
        override void unbind()
        {
            if( id_stack.length < 2 && id_stack[$-1] != id ) return;
            id_stack.length--;
            ntCheckGLCall!glBindFramebuffer( GL_FRAMEBUFFER, id_stack[$-1] );
            debug logger.trace( "bind [%d]", id_stack[$-1] );
        }
    }

    ///
    void drawBuffers( in int[] bufs... )
    {
        int max_bufs;
        checkGLCall!glGetIntegerv( GL_MAX_DRAW_BUFFERS, &max_bufs );
        enforce( bufs.length < max_bufs,
            new GLFBOException( format( "count of draw buffers greater what max value (%d>%d)", bufs.length, max_bufs ) ) );
        bind(); scope(exit) unbind();
        GLenum[] res;
        foreach( val; bufs )
            if( val < 0 ) res ~= GL_NONE;
            else res ~= cast(GLenum)( Attachment.COLOR + val );
        checkGLCall!glDrawBuffers( cast(int)res.length, res.ptr );
    }

    /// set render buffer as depth attachment
    void setDepth( GLRenderBuffer rbo )
    in{ assert( rbo !is null ); } body
    {
        bind(); scope(exit) unbind();
        setRBO( rbo, Attachment.DEPTH );
        logger.Debug( "[%d]", rbo.id );
    }

    /// set render buffer as color attachment
    void setColor( GLRenderBuffer rbo, uint no )
    in{ assert( rbo !is null ); } body
    {
        bind(); scope(exit) unbind();
        setRBO( rbo, cast(GLenum)( Attachment.COLOR + no ) );
        logger.Debug( "[%d] as COLOR%d", rbo.id, no );
    }

    /// set texture as depth attachment
    void setDepth( GLTexture tex )
    {
        bind(); scope(exit) unbind();
        setTex( tex, Attachment.DEPTH );
        logger.Debug( "[%d]", tex.id );
    }

    /// set texture as color attachment
    void setColor( GLTexture tex, uint no=0 )
    {
        bind(); scope(exit) unbind();
        setTex( tex, cast(GLenum)( Attachment.COLOR + no ) );
        logger.Debug( "[%d] as COLOR%d", tex.id, no );
    }

    /// `glCheckFramebufferStatus`
    void check()
    {
        bind(); scope(exit) unbind();
        auto status = checkGLCall!glCheckFramebufferStatus( GL_FRAMEBUFFER );
        import std.string;
        if( status != GL_FRAMEBUFFER_COMPLETE )
            throw new GLFBOException( format( "status isn't GL_FRAMEBUFFER_COMPLETE, it's %#x", status ) );
        logger.Debug( "pass" );
    }

protected:

    /// warning: no bind
    void setRBO( GLRenderBuffer rbo, GLenum attachment )
    in{ assert( rbo !is null ); } body
    {
        checkGLCall!glFramebufferRenderbuffer( GL_FRAMEBUFFER,
                            attachment, GL_RENDERBUFFER, rbo.id );
    }

    /// warning: no bind
    void texture1D( GLTexture tex, GLenum attachment, uint level=0 )
    in { assert( tex !is null ); } body
    {
        checkGLCall!glFramebufferTexture1D( GL_FRAMEBUFFER, attachment,
                                            tex.Target.T1D, tex.id, level );
    }

    /// warning: no bind
    void texture2D( GLTexture tex, GLenum attachment,
                    GLTexture.Target target=GLTexture.Target.T2D, uint level=0 )
    in { assert( tex !is null ); } body
    {
        checkGLCall!glFramebufferTexture2D( GL_FRAMEBUFFER, attachment,
                                            target, tex.id, level );
    }

    /// warning: no bind
    void texture3D( GLTexture tex, GLenum attachment, uint level=0, int layer=0 )
    in { assert( tex !is null ); } body
    {
        checkGLCall!glFramebufferTexture3D( GL_FRAMEBUFFER, attachment,
                                            tex.target, tex.id, level, layer );
    }

    /// warning: no bind
    void texture( GLTexture tex, GLenum attachment, uint level=0 )
    { checkGLCall!glFramebufferTexture( GL_FRAMEBUFFER, attachment, tex.id, level ); }

    /// warning: no bind
    void textureLayer( GLTexture tex, GLenum attachment, uint layer, uint level=0 )
    { checkGLCall!glFramebufferTextureLayer( GL_FRAMEBUFFER, attachment, tex.id, level, layer ); }


    /// warning: no bind
    void setTex( GLTexture tex, GLenum attachment, GLTexture.Target target=GLTexture.Target.T2D )
    {
        if( tex.target == tex.Target.T1D )
            texture1D( tex, attachment );
        else if( tex.target == tex.Target.T3D ||
                 tex.target == tex.Target.T2D_ARRAY ||
                 tex.target == tex.Target.CUBE_MAP_ARRAY )
            texture3D( tex, attachment );
        else
            texture2D( tex, attachment, target );
    }
}
