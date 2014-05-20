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

module desgui.base.glcontext;

public import desgui.core.context;
public import desgl.base.shader;

import desgui.base.gldraw;

/++
 стандартный шейдер для всех widget"ов

    uniform vec2 winsize - размер окна

    attribute vec2 vertex - позиция в системе координат окна
    attribute vec4 color  - цвет вершины
    attribute vec2 uv     - текстурная координата

    uniform sampler2D ttu   - текстурный сэмплер
    uniform int use_texture - флаг использования текстуры: 
                                0 - не использовать,
                                1 - использовать только альфу
                                2 - использовать все 4 канала текстуры

+/
private enum ShaderSource SS_GUI = 
{
`#version 120
uniform vec2 winsize;

attribute vec2 vertex;
attribute vec4 color;
attribute vec2 uv;

varying vec2 ex_uv;
varying vec4 ex_color;

void main(void)
{
    gl_Position = vec4( 2.0 * vec2(vertex.x, -vertex.y) / winsize + vec2(-1.0,1.0), -0.05, 1 );
    ex_uv = uv;
    ex_color = color;
}
`,

`#version 120
uniform sampler2D ttu;
uniform int use_texture;

varying vec2 ex_uv;
varying vec4 ex_color;

void main(void) 
{ 
    if( use_texture == 0 )
        gl_FragColor = ex_color; 
    else if( use_texture == 1 )
        gl_FragColor = vec4( 1, 1, 1, texture2D( ttu, ex_uv ).r ) * ex_color;
    else if( use_texture == 2 )
        gl_FragColor = texture2D( ttu, ex_uv );
}`
};

void log(size_t line=__LINE__, T...)( string fmt, T args )
{
    import std.stdio, std.string;
    stderr.writefln( "#% 4d: %s", line, format( fmt, args ) );
}

final abstract class DiGuiShader
{
private:
    static CommonShaderProgram main_shader;

public:
    static CommonShaderProgram get()
    {
        if( main_shader is null )
            main_shader = new CommonShaderProgram( SS_GUI );
        return main_shader;
    }

    static void set( CommonShaderProgram shader )
    {
        if( shader is null ) return;
        main_shader = shader;
    }
}

import std.array;
import derelict.opengl3.gl3;

class ViewportStateCtrl
{
private:
    struct PRect { irect viewport, scissor; }

    PRect[] states;
    PRect current;

    void update()
    {
        auto vp = current.viewport;
        auto sc = current.scissor;
        glViewport( vp.x,vp.y,vp.w,vp.h );
        glScissor( sc.x,sc.y,sc.w,sc.h );
    }

    nothrow static void setFromGL( ref PRect rr )
    {
        glGetIntegerv( GL_VIEWPORT, rr.viewport.vr.data.ptr );
        glGetIntegerv( GL_SCISSOR_BOX, rr.scissor.vr.data.ptr );
    }

public:

    this( in irect init ) { set( init ); }
    this(){ setFromGL( current ); }

    void push() { states ~= current; }

    void pull()
    {
        if( !states.empty )
        {
            current = states.back();
            states.popBack();
        }
        update();
    }

    irect sub( in irect vp )
    {
        auto cvp = current.viewport;
        auto csc = current.scissor;

        irect nvp;
        nvp.x = cvp.x + vp.x;
        nvp.y = cvp.y + cvp.h - ( vp.y + vp.h );
        nvp.w = vp.w;
        nvp.h = vp.h;

        irect nsc = csc.overlap( nvp );

        irect locsc;
        locsc.x = nsc.x - nvp.x;
        locsc.y = nvp.y + nvp.h - nsc.y - nsc.h;
        locsc.w = nsc.w;
        locsc.h = nsc.h;

        current.viewport = nvp;
        current.scissor = nsc;
        update();

        return locsc;
    }

    void set( in irect vp )
    {
        current.viewport = vp;
        current.scissor = vp;
        update();
    }

    void setClear( in irect vp )
    {
        states.length = 0;
        set( vp );
    }
}

class DiGLDrawStack: DiDrawStack
{
protected:

    struct stackData
    {
        vec2 offset, scale;
    }

    stackData[] data;
    size_t cur = 0;

    ViewportStateCtrl vpctl;
    CommonShaderProgram shader;

public:

    this()
    {
        vpctl = new ViewportStateCtrl;
        shader = DiGuiShader.get();
        data ~= stackData( vec2(0,0), vec2(1,1) );
    }

    void setClear( in irect r ) { vpctl.setClear( r ); }

    irect push( in DiViewport w )
    {
        auto cs = data[cur].scale;
        auto co = data[cur].offset;

        auto r = w.rect;
        //r.pos = ivec2( r.pos.elem!"*"(cs) + ivec2(co) ); 
        r.pos = ivec2( r.pos.elem!"*"(cs) + ivec2(co) ); 
        r.size = ivec2( r.size.elem!"*"(cs) );

        auto state = stackData( w.offset.elem!"*"(cs),
                                w.scale.elem!"*"(cs) );
        cur++;

        if( data.length > cur )
            data[cur] = state;
        else data ~= state;

        vpctl.push();
        shader.use();

        shader.setUniformVec( "winsize", vec2( w.rect.size ) );
        shader.setUniform!int( "use_texture", 0 );

        auto sub = vpctl.sub(r);
        sub.pos = ivec2( sub.pos.elem!"/"(cs) );
        sub.size = ivec2( sub.size.elem!"/"(cs) );

        return sub;
    }

    void pull()
    {
        cur--;
        vpctl.pull();
    }
}

import desgui.base.ftglyphrender;

class DiGLContext: DiContext
{
    DiDrawStack ds;
    DiGlyphRender gr;
    DiDrawFactory df;

    this( string fontname )
    {
        ds = new DiGLDrawStack();
        gr = FTGlyphRender.get( fontname );
        df = new DiGLDrawFactory;
    }

    @property DiDrawStack drawStack() { return ds; }
    @property DiGlyphRender baseGlyphRender() { return gr; }
    @property DiDrawFactory draw() { return df; }
}
