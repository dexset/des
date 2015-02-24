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
