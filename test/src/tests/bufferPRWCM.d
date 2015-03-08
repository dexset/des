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

        points.storage( [ vec2(0,.5), vec2(.3,-.3), vec2(-.3,-.3) ],
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
        float t0 = step / 90.0f;
        float t1 = step / 120.0f;
        float t2 = step / 1500.0f;

        data[0] = vec2( cos(t0), sin(t0) ) * R;
        data[1] = vec2( cos(t1), sin(t1) ) * R;
        data[2] = vec2( cos(t2), sin(t2) ) * R;
    }

    void draw()
    {
        shader.use();
        drawArrays( DrawMode.LINE_LOOP, 0, 3 );
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
        wstring info() { return "see you red rotated triangle? [y/N]:"w; }
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
