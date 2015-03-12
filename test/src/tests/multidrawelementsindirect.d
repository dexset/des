module tests.multidrawelementsindirect;

import tests.iface;

import std.math;

class MultiDrawElementsIndirectTest : GLDrawObject, Test
{
    bool answer = false;
    bool result = false;

    CommonGLShaderProgram shader;

    GLArrayBuffer points;
    GLElementArrayBuffer eab;
    GLDrawIndirectBuffer dib;

    size_t step;

    vec2[] getDoubleLined( vec2 offset, float r1, float r2,
                           float angle, uint n )
    {
        vec2[] ret;

        foreach( i; 0 .. n+1 )
        {
            auto t = angle + ( 2 * PI * i ) / n;
            ret ~= [ vec2( cos(t), sin(t) ) * r1 + offset,
                     vec2( cos(t), sin(t) ) * r2 + offset ];
        }

        return ret;
    }

    uint[] getDoubleLinedIndices( uint n )
    {
        uint[] l1, l2;

        for( uint i = 0; i < n + 1; i++ )
        {
            auto k = (i*2) % (n*2);
            l1 ~= k;
            l2 ~= k+1;
        }
        l1 ~= uint.max;
        l2 ~= uint.max;

        return l1 ~ l2;
    }

    void init()
    {
        shader = newEMM!CommonGLShaderProgram(
                parseGLShaderSource( SS_DRAW_VARIANTS ) );

        points = newEMM!GLArrayBuffer;
        eab = newEMM!GLElementArrayBuffer;
        dib = newEMM!GLDrawIndirectBuffer;

        alias DrawCmd = GLDrawIndirectBuffer.ElementCmd;

        DrawCmd[] drawcmd;
        vec2[] vertices, vbuf;
        uint[] indices, ibuf;

        void addFigure( vec2 offset, float angle, uint N, uint i )
        {
            vbuf = getDoubleLined( offset, 0.2, 0.1, angle, N );
            ibuf = getDoubleLinedIndices(N);
            drawcmd ~= DrawCmd( cast(uint)(ibuf.length), i,
                                cast(uint)(indices.length),
                                cast(uint)(vertices.length), 0 );
            vertices ~= vbuf;
            indices ~= ibuf;
        }

        addFigure( vec2(-.5,.5), PI_2, 3, 1 );
        addFigure( vec2(  0,.5), PI_4, 4, 2 );
        addFigure( vec2( .5,.5), PI_2, 5, 3 );

        addFigure( vec2(-.5,0), PI_4, 4, 3 );
        addFigure( vec2(  0,0), PI_2, 3, 4 );
        addFigure( vec2( .5,0),   0, 36, 5 );

        addFigure( vec2(-.5,-.5), PI_2, 36, 3 );
        addFigure( vec2(  0,-.5), PI_4, 4, 4 );
        addFigure( vec2( .5,-.5), PI_2, 5, 6 );

        auto sf = [ GLBuffer.StorageBits.WRITE ];
        points.storageData( vertices, sf );
        eab.storage( indices, sf );
        dib.storage( drawcmd, sf );

        setAttribPointer( points, 0, 2, GLType.FLOAT );

        glEnable( GL_PRIMITIVE_RESTART );
        glPrimitiveRestartIndex( uint.max );
    }

    void clear() { destroy(); }

    void idle() { }

    void draw()
    {
        shader.use();
        multiDrawElementsIndirect( DrawMode.LINE_STRIP, eab, dib );
    }

    void keyReaction( in KeyboardEvent ke )
    {
        if( !ke.pressed ) return;

        if( ke.scan == ke.Scan.Y )
        {
            answer = true;
            result = true;
        }

        if( ke.scan == ke.Scan.N )
        {
            answer = true;
            result = false;
        }
    }

    void mouseReaction( in MouseEvent ) { }
    void resize( ivec2 ) { }

    @property
    {
        wstring name() { return "draw variants"w; }
        wstring info() { return "9 full red figures with different colors duplicates [y/N]"w; }
        bool complite() { return answer; }
        bool success() { return result; }
    }
}

enum SS_DRAW_VARIANTS = `
//### vert
#version 430 core
layout(location=0) in vec2 pos;
layout(location=0) out vec3 out_color;
void main()
{
    vec2 offset = vec2(1,-1) * 0.08 * gl_InstanceID;

         if( gl_InstanceID == 0 ) out_color = vec3(1,0,0);
    else if( gl_InstanceID == 1 ) out_color = vec3(0,1,0);
    else if( gl_InstanceID == 2 ) out_color = vec3(0,0,1);
    else if( gl_InstanceID == 3 ) out_color = vec3(1,1,0);
    else if( gl_InstanceID == 4 ) out_color = vec3(0,1,1);
    else if( gl_InstanceID == 5 ) out_color = vec3(1,0,1);

    gl_Position = vec4(pos*(vec2(1)-offset),0,1);
}
//### frag
#version 430 core
layout(location=0) in vec3 in_color;
layout(location=0) out vec4 color;
void main() { color = vec4( in_color, 1 ); }
`;
