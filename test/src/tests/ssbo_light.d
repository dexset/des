module tests.ssbo_light;

import tests.iface;

import camera;

class SSBOLightTest : DesObject, Test
{
    bool answer = false;
    bool result = false;

    CommonGLShaderProgram shader;
    DrawSphere obj;

    GLShaderStorageBuffer light_buffer;

    Light[] lights;

    Timer timer;

    MouseControlCamera cam;

    bool lights_move = true;

    void init()
    {
        shader = newEMM!CommonGLShaderProgram(
                parseGLShaderSource( import("ssbo_light.glsl") ) );

        obj = newEMM!DrawSphere( convMesh(
                    smGetSphereMesh( "sphere", 2, 24, 24 ) ) );

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

            auto sll = amap!(a=>a.packed(cam))( lights );
            light_buffer.setData( sll, GLBuffer.Usage.DYNAMIC_DRAW );
        }
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
        if( ke.scan == ke.Scan.M ) lights_move = !lights_move;
    }

    void mouseReaction( in MouseEvent me )
    { cam.mouseReaction( me ); }

    void resize( ivec2 ) { }

    @property
    {
        wstring name() { return "ssbo lights"w; }
        wstring info() { return "see you lighted sphere? [y/N] move lights trigger [M]"w; }
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

        md.draw_mode = smMeshTypeToGLObjectDrawMode( m.type );
        md.num_vertices = cast(uint)( m.vertices.length );
        md.indices = m.indices.dup;

        md.attribs = [ vertexAttrib, tcoordAttrib, normalAttrib, tangentAttrib ];

        md.buffers ~= GLMeshData.Buffer( m.vertices.dup, [0] );

        if( m.texcoords !is null )
            md.buffers ~= GLMeshData.Buffer( getTexCoords( m.texcoords[0] ), [1] );

        md.buffers ~= GLMeshData.Buffer( m.normals.dup, [2] );

        if( m.tangents )
            md.buffers ~= GLMeshData.Buffer( m.tangents.dup, [3] );

        return md;
    }

    vec2[] getTexCoords( in SMTexCoord tc )
    {
        enforce( tc.comp == 2 );
        enforce( tc.data !is null );
        return cast(vec2[])tc.data.dup;
    }

    const @property
    {
        GLAttrib vertexAttrib() { return GLAttrib( "vertex", 0, 3 ); }
        GLAttrib tcoordAttrib() { return GLAttrib( "tcoord", 1, 2 ); }
        GLAttrib normalAttrib() { return GLAttrib( "normal", 2, 3 ); }
        GLAttrib tangentAttrib() { return GLAttrib( "tangent", 3, 3 ); }
    }
}

class DrawSphere : GLMeshObject, SpaceNode
{
    mixin DES;
    mixin SpaceNodeHelper;
    this( in GLMeshData md ) { super( md ); }
    void draw() { drawElements(); }
}

GLDrawObject.DrawMode smMeshTypeToGLObjectDrawMode( SMMesh.Type tp )
{
    final switch( tp )
    {
        case SMMesh.Type.POINTS:         return GLDrawObject.DrawMode.POINTS;
        case SMMesh.Type.LINES:          return GLDrawObject.DrawMode.LINES;
        case SMMesh.Type.LINE_STRIP:     return GLDrawObject.DrawMode.LINE_STRIP;
        case SMMesh.Type.TRIANGLES:      return GLDrawObject.DrawMode.TRIANGLES;
        case SMMesh.Type.TRIANGLE_STRIP: return GLDrawObject.DrawMode.TRIANGLE_STRIP;
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
