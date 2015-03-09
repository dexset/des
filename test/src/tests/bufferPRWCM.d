// persistent read/write coherent map
module tests.bufferPRWCM;

import tests.iface;

class BufferPRWCM : GLDrawObject, Test
{
    bool answer = false;
    bool result = false;

    GLArrayBuffer points;
    CommonGLShaderProgram shader;

    size_t step;

    vec2[] data;

    void init()
    {
        shader = newEMM!CommonGLShaderProgram( 
                parseGLShaderSource( SS_BUFFER_PRWCM ) );

        points = newEMM!GLArrayBuffer;

        points.storage( 30, vec2.sizeof,
                [ GLBuffer.StorageBits.READ,
                  GLBuffer.StorageBits.WRITE,
                  GLBuffer.StorageBits.PERSISTENT,
                  GLBuffer.StorageBits.COHERENT ] );

        setAttribPointer( points, 0, 2, GLType.FLOAT );

        data = points.mapData!vec2(
                GLBuffer.MapBits.READ,
                GLBuffer.MapBits.WRITE,
                GLBuffer.MapBits.PERSISTENT,
                GLBuffer.MapBits.COHERENT );
    }

    void clear()
    {
        points.unmap();
        destroy();
    }

    void idle()
    {
        import std.math;
        step++;

        float R = 0.5;

        foreach( i, ref p; data )
        {
            auto t = step / 200.0 * (1.0 + i*0.01);
            p = vec2( cos(t), sin(t*(1.0f + i*0.01)) ) * R;
        }
    }

    void draw()
    {
        shader.use();
        drawArrays( DrawMode.LINE_STRIP, 0, points.elementCount );
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
        wstring name() { return "buffer PRWCM"w; }
        wstring info() { return "see you red sin-moved line? [y/N]:"w; }
        bool complite() { return answer; }
        bool success() { return result; }
    }
}

enum SS_BUFFER_PRWCM = `
//### vert
#version 330 core
layout(location=0) in vec3 pos;
void main() { gl_Position = vec4(pos,1); }
//### frag
#version 330 core
layout(location=0) out vec4 color;
void main() { color = vec4(1,0,0,1); }
`;
