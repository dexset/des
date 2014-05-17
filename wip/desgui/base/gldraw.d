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

module desgui.base.gldraw;

public import desgui.core.draw;

import desgui.base.glcontext;

//import desgl.draw.rectshape;
import desgl.base;

import desil;

//class DiGLDrawRect : DiDrawRect
//{
//private:
//    ShaderProgram shader;
//    GLTexture2D texture;
//    UseTexture ut = UseTexture.NONE;
//    ColorTexRect!() plane;
//    col4 clr = col4(0,0,0,0);
//
//public:
//
//    this()
//    {
//        shader = DiGuiShader.get();
//
//        int ploc = shader.getAttribLocation( "vertex" );
//        int cloc = shader.getAttribLocation( "color" );
//        int tloc = shader.getAttribLocation( "uv" );
//
//        plane = new ColorTexRect!()( ploc, cloc, tloc );
//
//        texture = new GLTexture2D;
//
//        plane.draw.addBegin(
//        {
//            shader.use();
//            shader.setUniform!int( "ttu", GL_TEXTURE0 );
//            shader.setUniform!int( "use_texture", cast(int)useTexture );
//            texture.bind();
//        });
//
//        color = clr;
//    }
//
//    @property
//    {
//        ref UseTexture useTexture() { return ut; }
//        ref const(UseTexture) useTexture() const { return ut; }
//        irect rect() const { return plane.rect; }
//
//        col4 color() const { return clr; }
//        void color( in col4 c )
//        {
//            plane.setColor( c );
//            clr = c;
//        }
//    }
//
//    void reshape( in irect r ) { plane.reshape( r ); }
//
//    void draw() { plane.draw(); }
//
//    void image( in Image img ) { texture.image( img ); }
//
//    void image( in ImageReadAccess ira )
//    {
//        texture.image( ira );
//        if( !ira ) useTexture = UseTexture.NONE;
//    }
//}
//
//class DiGLDrawFactory : DiDrawFactory
//{
//    @property DiDrawRect rect() { return new DiGLDrawRect(); }
//}
