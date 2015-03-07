module draw;

import std.math;

import des.math.linear;
import des.util.stdext.algorithm;
import des.util.helpers;

import des.space;

import des.gl;
import des.assimp;

class Sphere : GLMeshObject, SpaceNode
{
    mixin SpaceNodeHelper;

protected:

    CommonGLShaderProgram shader;

public:

    this( float r, uint u, uint v )
    {
        super( convMesh( smGetSphereMesh( "sphere", r, u, v ) ) );
        import std.file;
        auto ss = parseGLShaderSource( readText( appPath(
                        "..", "data", "shaders", "object.glsl" ) ) );
        shader = newEMM!CommonGLShaderProgram( ss );
    }

    void draw( Camera cam )
    {
        shader.use();
        shader.setUniform!vec4( "col", vec4(1,0,0,1) );
        glEnable( GL_PRIMITIVE_RESTART );
        glPrimitiveRestartIndex(uint.max);
        glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
        shader.setUniform!mat4( "prj", cam.view(this) );
        drawElements();
        glDisable( GL_PRIMITIVE_RESTART );
    }

protected:

    GLMeshData convMesh( in SMMesh m )
    {
        GLMeshData md;

        enforce( m.vertices !is null );

        md.draw_mode = smMeshTypeToGLObjectDrawMode( m.type );
        md.num_vertices = cast(uint)( m.vertices.length );
        md.indices = m.indices.dup;

        md.attribs = [ vertexAttrib ];//, tcoordAttrib, normalAttrib, tangentAttrib ];

        md.buffers ~= GLMeshData.Buffer( m.vertices.dup, [0] );

        //if( m.texcoords !is null )
        //    md.buffers ~= GLMeshData.Buffer( getTexCoords( m.texcoords[0] ), [1] );

        //md.buffers ~= GLMeshData.Buffer( m.normals.dup, [2] );

        //if( m.tangents )
        //    md.buffers ~= GLMeshData.Buffer( m.tangents.dup, [3] );

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
