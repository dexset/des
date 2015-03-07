module des.gl.base.render;

import des.gl.base;
import des.il;

/// Render to FBO
class GLRender : DesObject
{
    mixin DES;
    mixin ClassLogger;
protected:

    ///
    GLFrameBuffer fbo;

    ///
    GLTexture depth_buf;

    ///
    GLTexture[uint] color_bufs;

    uivec2 buf_size;
    int[4] last_vp;

public:

    ///
    this() { fbo = newEMM!GLFrameBuffer; }

    ///
    GLTexture defaultDepth( uint unit )
    {
        auto tex = createDefaultTexture( unit );
        tex.image( ivec2(1,1), GLTexture.InternalFormat.DEPTH32F,
            GLTexture.Format.DEPTH, GLTexture.Type.FLOAT );
        return tex;
    }

    ///
    GLTexture defaultColor( uint unit )
    {
        auto tex = createDefaultTexture( unit );
        tex.image( ivec2(1,1), GLTexture.InternalFormat.RGBA,
            GLTexture.Format.RGBA, GLTexture.Type.FLOAT );
        return tex;
    }

    ///
    GLTexture getDepth() { return depth_buf; }

    ///
    void setDepth( GLTexture buf )
    in{ assert( buf !is null ); } body
    {
        if( depth_buf is buf )
        {
            // TODO: warning
            return;
        }

        removeIfChild( depth_buf );
        registerChildEMM( buf, true );
        depth_buf = buf;
        fbo.setDepth( buf );
        fbo.check();
    }

    /// get buffer setted to color attachment N
    GLTexture getColor( uint N )
    { return color_bufs.get( N, null ); }

    ///
    GLTexture[uint] getColors() { return color_bufs.dup; }

    /// set buf to color attachment N
    void setColor( GLTexture buf, uint N )
    in{ assert( buf !is null ); } body
    {
        if( auto tmp = color_bufs.get( N, null ) )
        {
            if( tmp is buf )
            {
                // TODO: warning
                return;
            }
            removeIfChild( tmp );
        }

        registerChildEMM( buf, true );
        color_bufs[N] = buf;
        fbo.setColor( buf, N );
        fbo.check();
    }

    ///
    void resize( uivec2 sz )
    {
        if( sz == buf_size ) return;
        if( depth_buf ) depth_buf.resize( sz );
        foreach( col; color_bufs ) col.resize( sz );
        buf_size = sz;
        logger.Debug( "[%d,%d]", sz.x, sz.y );
    }

    /// `GLFrameBuffer.drawBuffers`
    void drawBuffers( in int[] bufs... ) { fbo.drawBuffers( bufs ); }

    ///
    void resize( uint w, uint h ) { resize( uivec2( w, h ) ); }

    ///
    void bind()
    {
        fbo.bind();
        checkGLCall!glGetIntegerv( GL_VIEWPORT, last_vp.ptr );
        checkGLCall!glViewport( 0, 0, buf_size.x, buf_size.y );
    }

    ///
    void unbind()
    {
        fbo.unbind();
        checkGLCall!glViewport( last_vp[0], last_vp[1], last_vp[2], last_vp[3] );
    }

protected:

    auto createDefaultTexture( uint unit )
    {
        auto tex = new GLTexture( GLTexture.Target.T2D, unit );
        tex.setWrapS( GLTexture.Wrap.CLAMP_TO_EDGE );
        tex.setWrapT( GLTexture.Wrap.CLAMP_TO_EDGE );
        tex.setMinFilter( GLTexture.Filter.NEAREST );
        tex.setMagFilter( GLTexture.Filter.NEAREST );
        return tex;
    }

    void removeIfChild( GLTexture t )
    {
        if( depth_buf && findInChildsEMM( depth_buf ) )
        {
            depth_buf.destroy();
            detachChildsEMM( depth_buf );
        }
    }

    override void selfDestroy() { fbo.unbind(); }
}
