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

import desgl.base;

import desil;

auto dataArray(V)( size_t n, in V v )
    if( isVector!V )
{
    v.datatype[] ret;
    foreach( i; 0 .. n )
        ret ~= v.data;
    return ret;
}

class DiGLDrawRect : GLObj, DiDrawRect
{
private:
    GLVBO pos, col, uv;
    CommonShaderProgram shader;
    GLTexture2D texture;
    UseTexture ut = UseTexture.NONE;
    col4 clr = col4(0,0,0,0);
    irect last_rect;

public:

    this()
    {
        shader = DiGuiShader.get();
        int[] loc = shader.getAttribLocations( "vertex", "color", "uv" );

        pos = new GLVBO( [ 0.0f, 0, 1, 0, 0, 1, 1, 1 ] );
        setAttribPointer( pos, loc[0], 2, GL_FLOAT );

        col = new GLVBO( dataArray( 4, col4(1,1,1,1) ) );
        setAttribPointer( col, loc[1], 4, GL_FLOAT );

        uv = new GLVBO( [ 0.0f, 0, 1, 0, 0, 1, 1, 1 ], 
                        GL_ARRAY_BUFFER, GL_STATIC_DRAW );
        setAttribPointer( uv, loc[2], 2, GL_FLOAT );

        texture = new GLTexture2D;
    }

    @property
    {
        ref UseTexture useTexture() { return ut; }
        ref const(UseTexture) useTexture() const { return ut; }
        irect rect() const { return last_rect; }

        col4 color() const { return clr; }
        void color( in col4 c )
        {
            col.setData( dataArray( 4, c ) );
            clr = c;
        }
    }

    void reshape( in irect r )
    {
        last_rect = r;
        pos.setData( r.points!float ); 
    }

    void draw()
    {
        vao.bind();
        shader.use();
        shader.setUniform!int( "ttu", GL_TEXTURE0 );
        shader.setUniform!int( "use_texture", cast(int)useTexture );
        texture.bind();
        glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 ); 
    }

    void image( in Image img ) { texture.image( img ); }

    void image( in ImageReadAccess ira )
    {
        texture.image( ira );
        if( !ira ) useTexture = UseTexture.NONE;
    }
}

class DiGLDrawFactory : DiDrawFactory
{
    @property DiDrawRect rect() { return new DiGLDrawRect(); }
}
