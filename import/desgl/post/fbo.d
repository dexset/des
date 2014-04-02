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

//import desmath.linear;
//import desmath.types.rect;
//import desutil.signal;
//
//public import desgl.shader;
//import desgl.object;
//import desgl.texture;
//import desgl.helpers;
//
//import desil.image;
//
//import desutil.logger;
//mixin( PrivateLoggerMixin );
//
//class GLFBOException : Exception 
//{ @safe pure nothrow this( string msg ){ super( msg ); } }
//
//class GLFBO
//{
//private:
//    uint rboID;
//    uint fboID;
//
//    GLTexture2D tex;
//
//    static uint[] fboStack;
//
//    static this() { fboStack ~= 0; }
//
//    vec!(2,int,"wh") sz;
//
//public:
//
//    alias const ref ivec2 in_ivec2;
//    Signal!in_ivec2 resize;
//    SignalBoxNoArgs draw;
//
//    this()
//    {
//        sz = ivec2( 1, 1 );
//
//        tex = new GLTexture2D;
//        tex.image( sz, 4, GL_RGBA, GL_UNSIGNED_BYTE );
//
//        // Render buffer
//        glGenRenderbuffers( 1, &rboID );
//        glBindRenderbuffer( GL_RENDERBUFFER, rboID );
//        glRenderbufferStorage( GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, sz.w, sz.h );
//        glBindRenderbuffer( GL_RENDERBUFFER, 0 );
//
//        // Frame buffer
//        glGenFramebuffers( 1, &fboID );
//        glBindFramebuffer( GL_FRAMEBUFFER, fboID );
//        glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
//                                GL_TEXTURE_2D, tex.id, 0 );
//        glFramebufferRenderbuffer( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, 
//                                   GL_RENDERBUFFER, rboID );
//
//        GLenum status = glCheckFramebufferStatus( GL_FRAMEBUFFER );
//        import std.string;
//        if( status != GL_FRAMEBUFFER_COMPLETE )
//            throw new GLFBOException( format( "status isn't GL_FRAMEBUFFER_COMPLETE, it's %#x", status ) );
//
//        glBindFramebuffer( GL_FRAMEBUFFER, 0 );
//
//        debug log( "create FBO [fbo:%d], [rbo:%d], [tex:%d]", fboID, rboID, tex.id );
//
//        resize.connect( (nsz)
//        {
//            sz = nsz;
//
//            debug log( "reshape FBO: [ %d x %d ]", sz.w, sz.h );
//
//            tex.image( sz, 4, GL_RGBA, GL_UNSIGNED_BYTE );
//            tex.genMipmap();
//
//            glBindRenderbuffer( GL_RENDERBUFFER, rboID );
//            glRenderbufferStorage( GL_RENDERBUFFER, GL_DEPTH_COMPONENT, sz.w, sz.h );
//            glBindRenderbuffer( GL_RENDERBUFFER, 0 );
//        });
//
//        resize( ivec2(1,1) );
//    }
//
//    final nothrow void bind() 
//    { 
//        glBindFramebuffer( GL_FRAMEBUFFER, fboID ); 
//        fboStack ~= fboID;
//    }
//
//    final nothrow void unbind() 
//    { 
//        if( fboStack.length > 1 )
//        {
//            glBindFramebuffer( GL_FRAMEBUFFER, fboStack[$-2] ); 
//            fboStack = fboStack[ 0 .. $-1 ];
//        }
//    }
//
//    /+ TODO 
//        работу с текстурой переложить на GLTexture2D
//       TODO +/
//
//    final nothrow void bindTexture() { tex.bind(); }
//    final nothrow void unbindTexture() { tex.unbind(); }
//
//    final void getImage( ref Image img, uint level=0, GLenum fmt=GL_RGB, GLenum rtype=GL_UNSIGNED_BYTE )
//    { tex.getImage( img, level, fmt, rtype ); }
//
//    nothrow @property auto size() const { return sz; }
//
//    ~this()
//    {
//        unbind();
//        glDeleteFramebuffers( 1, &fboID );
//        glDeleteRenderbuffers( 1, &rboID );
//        //clear(tex);
//    }
//}
//
//import desgl.draw.rectshape;
//
//class GLFBODraw(Args...)
//{
//    GLFBO fbo;
//    TexturedRect!() obj;
//
//    SignalBox!Args render, draw;
//
//    this( int posloc, int uvloc )
//    {
//        fbo = new GLFBO;
//
//        obj = new TexturedRect!()( posloc, uvloc );
//
//        render.addBegin( (Args a) { fbo.bind(); } );
//        render.addEnd( (Args a) { fbo.unbind(); } );
//
//        draw.addBegin( (Args a) { fbo.bindTexture(); });
//        draw.connect( (Args a) { obj.draw(); } );
//    }
//}
