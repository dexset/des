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

module desgl.post.fbo;

import derelict.opengl3.gl3;

import desmath.linear;
import desutil.signal;
import desutil.emm;

import desgl.base;
import desutil.signal;
import desil;

import desutil.logger;
mixin( PrivateLoggerMixin );

class SimpleFBO : ExternalMemoryManager
{
mixin( getMixinChildEMM );
protected:
    
    GLRenderBuffer rbo;
    GLFrameBuffer fbo;

    GLTexture tex;

    vec!(2,int,"wh") sz;

public:

    alias const ref ivec2 in_ivec2;
    Signal!in_ivec2 resize;
    SignalBoxNoArgs draw;

    this()
    {
        sz = ivec2( 1, 1 );

        tex = registerChildEMM( new GLTexture(GLTexture.Target.T2D) );
        tex.image( sz, tex.InternalFormat.RGBA, tex.Format.RGBA, GLType.FLOAT );
        tex.parameteri( GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
        tex.parameteri( GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

        // Render buffer
        rbo = registerChildEMM( new GLRenderBuffer );
        rbo.storage( sz.wh, rbo.Format.DEPTH_COMPONENT24 );

        fbo = registerChildEMM( new GLFrameBuffer );
        // Frame buffer
        fbo.texture( tex, fbo.Attachment.COLOR0 );
        fbo.renderBuffer( rbo, fbo.Attachment.DEPTH );
        fbo.unbind();

        debug log( "create FBO [fbo:%d], [rbo:%d], [tex:%d]", fbo.id, rbo.id, tex.id );

        resize.connect( (nsz)
        {
            sz = nsz;

            debug log( "reshape FBO: [ %d x %d ]", sz.w, sz.h );

            tex.image( sz, tex.InternalFormat.RGBA, tex.Format.RGBA, GLType.FLOAT );
            tex.genMipmap();

            rbo.storage( sz.wh, rbo.Format.DEPTH_COMPONENT24 );
        });

        resize( ivec2(1,1) );
    }

    final nothrow
    {
        void bind() { fbo.bind(); }
        void unbind() { fbo.unbind(); }

        void textureBind() { tex.bind(); }
        void textureUnbind() { tex.unbind(); }
    }

    final void getImage( ref Image img, uint level=0, 
            GLTexture.Format fmt=GLTexture.Format.RGB, 
            GLBaseType rtype=GLBaseType.UNSIGNED_BYTE )
    { tex.getImage( img, level, fmt, rtype ); }

    nothrow @property auto size() const { return sz; }

    protected void selfDestroy()
    {
        unbind();
        textureUnbind();
    }
}

class FBORect: GLObj
{
private:
    SimpleFBO sfbo;
    GLBuffer pos, uv;
    ivec2 wsz = ivec2(800,800);
public:

    CommonShaderProgram shader;

    this( in ShaderSource ss )
    {
        shader = registerChildEMM( new CommonShaderProgram(ss) );
        sfbo = registerChildEMM( new SimpleFBO );

        sfbo.resize( wsz );

        int pos_loc = shader.getAttribLocation( "vertex" );
        int uv_loc = shader.getAttribLocation( "uv" );

        auto pos_dt = [ vec2(-1, 1), vec2(1, 1), vec2(-1,-1), vec2(1,-1) ];
        auto uv_dt =  [ vec2( 0, 1), vec2(1, 1), vec2( 0, 0), vec2(1, 0) ];

        pos = registerChildEMM( new GLBuffer( GLBuffer.Target.ARRAY_BUFFER ) );
        pos.setData( pos_dt, GLBuffer.Usage.STATIC_DRAW );
        setAttribPointer( pos, pos_loc, 2, GLBaseType.FLOAT );

        uv = registerChildEMM( new GLBuffer( GLBuffer.Target.ARRAY_BUFFER ) );
        pos.setData( uv_dt, GLBuffer.Usage.STATIC_DRAW );
        setAttribPointer( uv, uv_loc, 2, GLBaseType.FLOAT );
    }

    void bind(bool clear=true)
    { 
        sfbo.bind();
        if( clear ) glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    }

    void resize( in ivec2 sz )
    {
        wsz = sz;
        sfbo.resize( wsz );
    }

    void unbind() { sfbo.unbind(); }

    void predraw()
    {
        vao.bind();
        shader.use();
        sfbo.textureBind();
        shader.setUniformVec( "winsize", vec2(wsz) );
    }

    void draw()
    {
        glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );
    }
}
