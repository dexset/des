module tests.texture_cube;

import tests.iface;

import camera;
import meshnode;

class TextureCubeTest : DesObject, Test
{
    bool answer = false;
    bool result = false;

    MouseControlCamera cam;
    CommonGLShaderProgram shader;
    MeshNode obj;

    GLTextureCubeMap texCM;

    void init()
    {
        shader = newEMM!CommonGLShaderProgram(
                parseGLShaderSource( import("texture_cube.glsl") ) );

        obj = newEMM!MeshNode( convMesh(
                    smGetSphereMesh( "sphere", 1, 32, 32 ) ) );

        texCM = newEMM!GLTextureCubeMap( 0 );

        auto texImg = imLoad( appPath("..","data","textures","light_cube_map.png" ), false );
        uint w = cast(uint)(texImg.size.h / 3);
        texCM.setImages( texImg, w, [ uivec2(0,w), uivec2(2*w,w),
                                      uivec2(w,w), uivec2(3*w,w),
                                      uivec2(w,0), uivec2(w,2*w) ],
                                    [ ImRepack.ROT90, ImRepack.ROT270,
                                      ImRepack.ROT180, ImRepack.NONE,
                                      ImRepack.ROT180, ImRepack.NONE ]
                                     );

        texCM.setMinFilter( GLTexture.Filter.LINEAR );
        texCM.setMagFilter( GLTexture.Filter.LINEAR );

        cam = newEMM!MouseControlCamera;
    }

    void clear() { destroy(); }

    void idle()
    {

    }

    void draw()
    {
        shader.use();

        auto cs = cam.resolve(obj);
        auto fprj = cam.projectMatrix * cs;
        glEnable( GL_DEPTH_TEST );
        shader.setUniform!mat4( "fprj", fprj );
        shader.setTexture( "texCM", texCM );
        obj.draw();
    }

    void keyReaction( in KeyboardEvent ke )
    {
        cam.keyReaction( ke );
        if( !ke.pressed ) return;

        if( ke.scan == ke.Scan.Y ) { answer = true; result = true; }
        if( ke.scan == ke.Scan.N ) { answer = true; result = false; }
    }

    void mouseReaction( in MouseEvent me ) { cam.mouseReaction( me ); }

    void resize( ivec2 sz ) { cam.ratio = sz.w / cast(float)(sz.h); }

    @property
    {
        wstring name() { return "texture test"w; }
        wstring info() { return "[y/N]"w; }
        bool complite() { return answer; }
        bool success() { return result; }
    }

protected:

    GLMeshData convMesh( in SMMesh m )
    {
        GLMeshData md;

        enforce( m.vertices !is null );

        md.draw_mode = smConvMeshTypeToDrawMode( m.type );
        md.num_vertices = cast(uint)( m.vertices.length );
        md.indices = m.indices.dup;

        md.attribs = [ vertexAttrib,
                       tcoordAttrib,
                     ];

        md.buffers ~= GLMeshData.Buffer( m.vertices.dup, [0] ); // md.attribs[0]

        enforce( m.texcoords.length );
        enforce( m.texcoords[0].comp == 2 );
        enforce( m.texcoords[0].data !is null );

        md.buffers ~= GLMeshData.Buffer( m.texcoords[0].data.dup, [1] );   // md.attribs[1]

        return md;
    }

    const @property
    {
        GLAttrib vertexAttrib() { return GLAttrib( "vertex", 0, 3 ); }
        GLAttrib tcoordAttrib() { return GLAttrib( "tcoord", 1, 2 ); }
    }
}
