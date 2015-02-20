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

module des.gl.base.render;

import des.math.linear;
import des.gl.base;
import des.il;

private template staticChoise(bool s,A,B)
{
    static if(s)
        alias A staticChoise;
    else
        alias B staticChoise;
}

private template createNew(bool buffer)
{
    auto fnc()
    {
        static if(buffer)
            return new GLRenderBuffer;
        else
        {
            auto tex = new GLTexture( GLTexture.Target.T2D );

            tex.setWrapS( GLTexture.Wrap.CLAMP_TO_EDGE );
            tex.setWrapT( GLTexture.Wrap.CLAMP_TO_EDGE );
            tex.setMinFilter( GLTexture.Filter.NEAREST );
            tex.setMagFilter( GLTexture.Filter.NEAREST );

            return tex;
        }
    }

    alias createNew=fnc;
}

/// Render to FBO
class GLRender(bool CB, bool DB) : DesObject
{
    mixin DES;
    mixin ClassLogger;
protected:

    GLFrameBuffer fbo;

public:

    ///
    alias staticChoise!(CB,GLRenderBuffer,GLTexture) ColorObject;
    ///
    alias staticChoise!(DB,GLRenderBuffer,GLTexture) DepthObject;

    ///
    DepthObject depth;
    ///
    ColorObject color;

    ///
    this()
    {
        depth = registerChildEMM( createDepth() );
        color = registerChildEMM( createColor() );

        resize( uivec2(1,1) );

        fbo = newEMM!GLFrameBuffer;
        fbo.setAttachment( depth, fbo.Attachment.DEPTH );
        fbo.setAttachment( color, fbo.Attachment.COLOR0 );
        fbo.unbind();

        debug logger.Debug( "FBO [%d], color [%s][%d], depth [%s][%d]",
                fbo.id, CB?"RB":"Tex", color.id, DB?"RB":"Tex", depth.id );
    }

    /// render
    void opCall( uivec2 sz, void delegate() draw_func )
    in
    {
        assert( sz.x > 0 );
        assert( sz.y > 0 );
        assert( draw_func !is null );
    }
    body
    {
        int[4] vpbuf;

        resize( sz );
        fbo.bind();
        glGetIntegerv( GL_VIEWPORT, vpbuf.ptr );
        glViewport( 0, 0, sz.x, sz.y );

        draw_func();

        fbo.unbind();
        glViewport( vpbuf[0], vpbuf[1], vpbuf[2], vpbuf[3] );

        debug logger.trace( "FBO [%d], size [%d,%d]", fbo.id, sz[0], sz[1] );
    }

protected:

    DepthObject createDepth()
    {
        auto tmp = createNew!DB();
        static if(DB) tmp.storage( ivec2(1,1), tmp.Format.DEPTH_COMPONENT32F );
        else tmp.image( ivec2(1,1), tmp.InternalFormat.DEPTH_COMPONENT,
                tmp.Format.DEPTH, tmp.Type.FLOAT );
        return tmp;
    }

    ColorObject createColor()
    {
        auto tmp = createNew!CB();
        static if(CB) tmp.storage( ivec2(1,1), tmp.Format.RGBA8 );
        else tmp.image( ivec2(1,1), tmp.InternalFormat.RGBA,
                tmp.Format.RGBA, tmp.Type.FLOAT );
        return tmp;
    }

    void resize( uivec2 sz )
    {
        depth.resize( sz );
        color.resize( sz );
    }

    override void selfDestroy()
    {
        fbo.unbind();
        static if(!DB) depth.unbind();
        static if(!CB) color.unbind();
    }
}

///
alias GLRender!(false,false) GLRenderToTex;
///
alias GLRender!(true,true) GLRenderToRB;
///
alias GLRender!(false,true) GLRenderColorToTexDepthToRB;
///
alias GLRender!(true,false) GLRenderColorToRBDepthToTex;
