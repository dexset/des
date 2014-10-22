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

module des.gl.post.render;

import des.util.emm;
import des.math.linear;
import des.gl.base;
import des.il;

class Render : ExternalMemoryManager
{
    mixin( getMixinChildEMM );
protected:

    GLFrameBuffer fbo;

public:

    GLTexture depth, color;

    this()
    {
        depth = newEMM!GLTexture(GLTexture.Target.T2D);
        color = newEMM!GLTexture(GLTexture.Target.T2D);

        depth.setParameter( GLTexture.Parameter.WRAP_S, GLTexture.Wrap.CLAMP_TO_EDGE );
        depth.setParameter( GLTexture.Parameter.WRAP_T, GLTexture.Wrap.CLAMP_TO_EDGE );
        depth.setParameter( GLTexture.Parameter.MIN_FILTER, GLTexture.Filter.NEAREST );
        depth.setParameter( GLTexture.Parameter.MAG_FILTER, GLTexture.Filter.NEAREST );

        color.setParameter( GLTexture.Parameter.WRAP_S, GLTexture.Wrap.CLAMP_TO_EDGE );
        color.setParameter( GLTexture.Parameter.WRAP_T, GLTexture.Wrap.CLAMP_TO_EDGE );
        color.setParameter( GLTexture.Parameter.MIN_FILTER, GLTexture.Filter.NEAREST );
        color.setParameter( GLTexture.Parameter.MAG_FILTER, GLTexture.Filter.NEAREST );

        resize( ivec2(1,1) );

        fbo = newEMM!GLFrameBuffer;
        fbo.texture( depth, fbo.Attachment.DEPTH );
        fbo.texture( color, fbo.Attachment.COLOR0 );
        fbo.unbind();
    }

    void opCall( ivec2 sz, void delegate() draw_func )
    in
    {
        assert( sz.x > 0 );
        assert( sz.y > 0 );
        assert( draw_func !is null );
    }
    body
    {
        resize( sz );

        fbo.bind();

        int[4] vpbuf;
        glGetIntegerv( GL_VIEWPORT, vpbuf.ptr );
        glViewport( 0, 0, sz.x, sz.y );

        glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

        draw_func();

        fbo.unbind();

        glViewport( vpbuf[0], vpbuf[1], vpbuf[2], vpbuf[3] );
    }

protected:

    void resize( ivec2 sz )
    {
        depth.image( sz, GLTexture.InternalFormat.DEPTH_COMPONENT, GLTexture.Format.DEPTH, GLTexture.Type.FLOAT );
        color.image( sz, GLTexture.InternalFormat.RGBA, GLTexture.Format.RGBA, GLTexture.Type.FLOAT );
    }

    void selfDestroy()
    {
        fbo.unbind();
        depth.unbind();
        color.unbind();
    }
}
