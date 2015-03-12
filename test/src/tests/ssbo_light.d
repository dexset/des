module tests.ssbo_light;

import tests.iface;

import camera;
import meshnode;

class SSBOLightTest : DesObject, Test
{
    bool answer = false;
    bool result = false;

    CommonGLShaderProgram shader;
    MeshNode obj;

    GLShaderStorageBuffer light_buffer;

    Light[] lights;

    Timer timer;

    MouseControlCamera cam;

    bool lights_move = true;

    void init()
    {
        shader = newEMM!CommonGLShaderProgram(
                parseGLShaderSource( import("ssbo_light.glsl") ) );

        obj = newEMM!MeshNode( convMesh(
                    smGetSphereMesh( "sphere", 2, 32, 32 ) ) );

        cam = newEMM!MouseControlCamera;

        timer = newEMM!Timer;

        prepareLights();
    }

    void clear() { destroy(); }

    void idle()
    {
        auto dt = timer.cycle();

        if( lights_move )
        {
            foreach( i, l; lights )
            {
                auto a = lights[(i+1)%$].ltr.pos.e;
                auto q = quat.fromAngle( .8 * dt, a );
                l.ltr.pos = q.rot(l.ltr.pos);
            }
        }

        auto sll = amap!(a=>a.packed(cam))( lights );
        light_buffer.setData( sll, GLBuffer.Usage.DYNAMIC_DRAW );
    }

    void draw()
    {
        shader.use();
        auto cs = cam.resolve(obj);
        auto fprj = cam.projectMatrix * cs;
        glEnable( GL_DEPTH_TEST );
        shader.setUniform!mat4( "camspace", cs );
        shader.setUniform!mat4( "fprj", fprj );
        obj.draw();
    }

    void keyReaction( in KeyboardEvent ke )
    {
        cam.keyReaction( ke );
        if( !ke.pressed ) return;

        if( ke.scan == ke.Scan.Y ) { answer = true; result = true; }
        if( ke.scan == ke.Scan.N ) { answer = true; result = false; }
        if( ke.scan == ke.Scan.L ) lights_move = !lights_move;
    }

    void mouseReaction( in MouseEvent me ) { cam.mouseReaction( me ); }

    void resize( ivec2 ) { }

    @property
    {
        wstring name() { return "ssbo lights"w; }
        wstring info() { return "lighted sphere [y/N] move lights trigger [L]"w; }
        bool complite() { return answer; }
        bool success() { return result; }
    }

protected:

    void prepareLights()
    {
        vec3 rndVector()
        {
            import std.random;
            float rndF() { return uniform(-1.0f,1.0f); }
            return vec3( rndF, rndF, rndF );
        }

        foreach( i; 0 .. 50 )
        {
            auto buf = newEMM!Light();
            buf.ltr.pos = rndVector().e * 5;
            buf.intensity = 10;
            buf.attenuation = 200;
            buf.color = rndVector() * .5 + vec3(.5);
            lights ~= buf;
        }

        light_buffer = newEMM!GLShaderStorageBuffer;
        light_buffer.bindBase(2);
    }

    GLMeshData convMesh( in SMMesh m )
    {
        GLMeshData md;

        enforce( m.vertices !is null );

        md.draw_mode = smConvMeshTypeToDrawMode( m.type );
        md.num_vertices = cast(uint)( m.vertices.length );
        md.indices = m.indices.dup;

        md.attribs = [ vertexAttrib, normalAttrib ];

        md.buffers ~= GLMeshData.Buffer( m.vertices.dup, [0] );
        md.buffers ~= GLMeshData.Buffer( m.normals.dup, [1] );

        return md;
    }

    const @property
    {
        GLAttrib vertexAttrib() { return GLAttrib( "vertex", 0, 3 ); }
        GLAttrib normalAttrib() { return GLAttrib( "normal", 1, 3 ); }
    }
}

class Light : DesObject, Camera
{
    mixin DES;
    mixin CameraHelper;

public:

    LookAtTransform ltr;
    int type = 0;
    float[7] type_data;
    float intensity = 100;
    vec3 color = vec3(1);
    float attenuation = 100;

    this()
    {
        ltr = new LookAtTransform;
        transform = ltr;
        ltr.up = vec3(0,0,1);
        ltr.target = vec3(0,0,0);

        auto pp = new OrthoTransform;
        pp.scale = 10;
        pp.ratio = 1;
        pp.near = 0.1;
        pp.far = 100;
        projection = pp;

        resolver = new Resolver;
    }

    SLight packed( Camera cam )
    {
        auto rs = this.resolve(cam);
        SLight ret;
        ret.pos = rs.speedTransformInv.offset;
        ret.cs2local = rs;
        ret.type = type;
        ret.type_data = type_data;
        ret.color = color;
        ret.intensity = intensity;
        ret.attenuation = attenuation;
        return ret;
    }
}

struct SLight
{
    vec3 pos;
    int type;
    mat4 cs2local;
    vec3 color;
    float intensity;
    float attenuation;
    float[7] type_data;
}
