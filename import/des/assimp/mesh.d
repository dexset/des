module des.assimp.mesh;

public import des.math.linear;

///
struct SMTexCoord
{
    /// count of components
    uint comp;
    ///
    float[] data;
}

///
struct SMMesh
{
    ///
    enum Type
    {
        POINTS,
        LINES,
        LINE_STRIP,
        TRIANGLES,
        TRIANGLE_STRIP
    }

    Type type = Type.TRIANGLES;

    ///
    string name;

    ///
    uint[] indices;

    ///
    vec3[] vertices;
    ///
    SMTexCoord[] texcoords;
    ///
    vec3[] normals;
    ///
    vec3[] tangents;
    ///
    vec3[] bitangents;
    ///
    vec4[][] colors;
}
