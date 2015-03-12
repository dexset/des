module tests.simpletexture;

import tests.iface;

import camera;
import meshnode;

class SimpleTextureTest : DesObject, Test
{
    bool answer = false;
    bool result = false;

    MouseControlCamera cam;
    CommonGLShaderProgram shader;
    MeshNode obj;

    //GLTexture2DArray tex2DArr;

    void init()
    {
        shader = newEMM!CommonGLShaderProgram(
                parseGLShaderSource( import("simple_texture.glsl") ) );

        obj = newEMM!MeshNode( convMesh(
                    smGetSphereMesh( "sphere", 1, 32, 32 ) ) );

        //tex2DArr = newEMM!GLTexture2DArray

        cam = newEMM!MouseControlCamera;
    }

    void clear() { destroy(); }

    void idle()
    {

    }

    void draw()
    {

    }

    void keyReaction( in KeyboardEvent ke )
    {
        cam.keyReaction( ke );
        if( !ke.pressed ) return;

        if( ke.scan == ke.Scan.Y ) { answer = true; result = true; }
        if( ke.scan == ke.Scan.N ) { answer = true; result = false; }
    }

    void mouseReaction( in MouseEvent me ) { cam.mouseReaction( me ); }

    void resize( ivec2 )
    {

    }

    @property
    {
        wstring name() { return "texture test"w; }
        wstring info() { return ""w; }
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
