module meshnode;

import des.gl;
import des.space;
import des.assimp;

class MeshNode : GLMeshObject, SpaceNode
{
    mixin DES;
    mixin SpaceNodeHelper;
    this( in GLMeshData md ) { super( md ); }
    void draw() { drawElements(); }
}

GLDrawObject.DrawMode smConvMeshTypeToDrawMode( SMMesh.Type tp )
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
