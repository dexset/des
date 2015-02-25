module des.assimp.loader;

import derelict.assimp3.assimp;
import derelict.assimp3.types;

import des.util.helpers;
import des.util.arch;
import des.util.data.type;
import des.util.stdext.string;

import des.assimp.mesh;

///
class SMLoaderException : Exception
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); }
}

///
class SMLoader : DesObject
{
    mixin DES;
protected:

    string scene_file_name;
    const(aiScene)* scene;

    string sourceName() const @property
    { return "scene '" ~ scene_file_name ~ "'"; }

public:

    /// process scene before loading, use Assimp3 documentation for more information
    enum PostProcess
    {
        /// Calculates the tangents and bitangents for the imported meshes.
        CalcTangentSpace = aiProcess_CalcTangentSpace,

        /// Identifies and joins identical vertex data sets within all imported meshes.
        JoinIdenticalVertices = aiProcess_JoinIdenticalVertices,

        /// Converts all the imported data to a left-handed coordinate space.
        MakeLeftHanded = aiProcess_MakeLeftHanded,

        /// Triangulates all faces of all meshes.
        Triangulate = aiProcess_Triangulate,

        /++ Removes some parts of the data structure (animations, materials,
            light sources, cameras, textures, vertex components).  +/
        //RemoveComponent = aiProcess_RemoveComponent,

        /// Generates normals for all faces of all meshes.
        GenNormals = aiProcess_GenNormals,

        /// Generates smooth normals for all vertices in the mesh.
        GenSmoothNormals = aiProcess_GenSmoothNormals,

        /// Splits large meshes into smaller sub-meshes.
        SplitLargeMeshes = aiProcess_SplitLargeMeshes,

        /++ <hr>Removes the node graph and pre-transforms all vertices with
        the local transformation matrices of their nodes. +/
        PreTransformVertices = aiProcess_PreTransformVertices,

        /// Limits the number of bones simultaneously affecting a single vertex to a maximum value.
        LimitBoneWeights = aiProcess_LimitBoneWeights,

        /// Validates the imported scene data structure.
        ValidateDataStructure = aiProcess_ValidateDataStructure,

        /// Reorders triangles for better vertex cache locality.
        ImproveCacheLocality = aiProcess_ImproveCacheLocality,

        /// Searches for redundant/unreferenced materials and removes them.
        RemoveRedundantMaterials = aiProcess_RemoveRedundantMaterials,

        /++ This step tries to determine which meshes have normal vectors
            that are facing inwards and inverts them. +/
        FixInFacingNormals = aiProcess_FixInFacingNormals,

        /++ This step splits meshes with more than one primitive type in
            homogeneous sub-meshes. +/
        SortByPType = aiProcess_SortByPType,

        /++ This step searches all meshes for degenerate primitives and
            converts them to proper lines or points. +/
        FindDegenerates = aiProcess_FindDegenerates,

        /++ This step searches all meshes for invalid data, such as zeroed
            normal vectors or invalid UV coords and removes/fixes them. This is
            intended to get rid of some common exporter errors. +/
        FindInvalidData = aiProcess_FindInvalidData,

        /++ This step converts non-UV mappings (such as spherical or
            cylindrical mapping) to proper texture coordinate channels. +/
        GenUVCoords = aiProcess_GenUVCoords,

        /++ This step applies per-texture UV transformations and bakes
            them into stand-alone vtexture coordinate channels. +/
        TransformUVCoords = aiProcess_TransformUVCoords,

        /++ This step searches for duplicate meshes and replaces them
            with references to the first mesh. +/
        FindInstances = aiProcess_FindInstances,

        /// A postprocessing step to reduce the number of meshes.
        OptimizeMeshes = aiProcess_OptimizeMeshes,

        /// A postprocessing step to optimize the scene hierarchy.
        OptimizeGraph = aiProcess_OptimizeGraph,

        /++ This step flips all UV coordinates along the y-axis and adjusts
            material settings and bitangents accordingly. +/
        FlipUVs = aiProcess_FlipUVs,

        /// This step adjusts the output face winding order to be CW.
        FlipWindingOrder = aiProcess_FlipWindingOrder,

        /++ This step splits meshes with many bones into sub-meshes so that each
            su-bmesh has fewer or as many bones as a given limit. +/
        SplitByBoneCount = aiProcess_SplitByBoneCount,

        /// This step removes bones losslessly or according to some threshold.
        Debone = aiProcess_Debone,

        // aiProcess_GenEntityMeshes = 0x100000,
        // aiProcess_OptimizeAnimations = 0x200000
        // aiProcess_FixTexturePaths = 0x200000
    };

    ///
    this()
    {
        if( !DerelictASSIMP3.isLoaded )
            DerelictASSIMP3.load();
    }

    ///
    PostProcess[] default_post_process = [ PostProcess.OptimizeMeshes,
                                           PostProcess.CalcTangentSpace,
                                           PostProcess.JoinIdenticalVertices,
                                           PostProcess.Triangulate ];

    ///
    void loadScene( string fname, PostProcess[] pp... )
    {
        scene_file_name = fname;
        scene = aiImportFile( fname.toStringz,
                buildFlags( default_post_process ~ pp ) );
    }

    ///
    SMMesh getMesh( string name )
    {
        foreach( i; 0 .. scene.mNumMeshes )
            if( toDStringFix( scene.mMeshes[i].mName.data ) == name )
                return convMesh( scene.mMeshes[i] );
        throw new SMLoaderException( "no mesh '" ~ name ~
                                     "' in " ~ sourceName );
    }

    ///
    SMMesh getMesh( size_t no )
    {
        if( no < scene.mNumMeshes )
            return convMesh( scene.mMeshes[no] );
        throw new SMLoaderException( "no mesh #" ~ to!string(no) ~
                                     " in " ~ sourceName );
    }

protected:

    SMMesh convMesh( in aiMesh* m )
    in{ assert( m !is null ); } body
    {
        return SMMesh
        (
            SMMesh.Type.TRIANGLES,
            toDStringFix( m.mName.data ),
            getIndices( m ),
            getVertices( m ),
            getTexCoords( m ),
            getNormals( m ),
            getTangents( m ),
            getBitangents( m ),
            getColors( m )
        );
    }

    uint[] getIndices( in aiMesh* m )
    {
        uint[] ret;

        foreach( i; 0 .. m.mNumFaces )
        {
            auto f = m.mFaces[i];
            enforce( f.mNumIndices == 3, new SMLoaderException( "one or more faces is not triangle" ) );
            ret ~= getTypedArray!uint( 3, f.mIndices ).arr;
        }

        return ret;
    }

    vec3[] getVertices( in aiMesh* m )
    { return getVertVectors( m, m.mVertices ); }

    vec3[] getNormals( in aiMesh* m )
    { return getVertVectors( m, m.mNormals ); }

    vec3[] getTangents( in aiMesh* m )
    { return getVertVectors( m, m.mTangents ); }

    vec3[] getBitangents( in aiMesh* m )
    { return getVertVectors( m, m.mBitangents ); }

    vec3[] getVertVectors( in aiMesh* m, in aiVector3D* buf )
    {
        if( buf is null ) return null;
        return getTypedArray!vec3( m.mNumVertices, buf ).arr.dup;
    }

    SMTexCoord[] getTexCoords( in aiMesh* m )
    {
        SMTexCoord[] ret;
        foreach( t; 0 .. AI_MAX_NUMBER_OF_TEXTURECOORDS )
        {
            auto tc = m.mTextureCoords[t];
            if( tc is null ) continue;
            auto nvert = m.mNumVertices;
            auto comp = m.mNumUVComponents[t];
            auto buf = new float[]( comp * nvert );
            foreach( i; 0 .. nvert )
                foreach( j; 0 .. comp )
                    buf[i*comp+j] = *(cast(float*)( tc + i ) + j);
            ret ~= SMTexCoord( comp, buf );
        }
        return ret;
    }

    vec4[][] getColors( in aiMesh* m )
    {
        vec4[][] ret;

        foreach( i; 0 .. AI_MAX_NUMBER_OF_COLOR_SETS )
        {
            if( m.mColors[i] is null ) continue;
            ret ~= getTypedArray!vec4( m.mNumVertices, m.mColors[i] ).arr.dup;
        }

        return ret;
    }
}
