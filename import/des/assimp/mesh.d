module des.assimp.mesh;

public import des.math.linear;

///
struct SRTexCoord
{
    /// count of components
    uint comp;
    ///
    float[] data;
}

///
struct SRMesh
{
    ///
    string name;

    ///
    uint[] indices;

    ///
    vec3[] vertices;
    ///
    SRTexCoord[] texcoords;
    ///
    vec3[] normals;
    ///
    vec3[] tangents;
    ///
    vec3[] bitangents;
    ///
    vec4[][] colors;
}
