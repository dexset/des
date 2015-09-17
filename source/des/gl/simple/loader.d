module des.gl.simple.loader;

import derelict.assimp3.assimp;
import derelict.assimp3.types;

import des.math.linear;
import des.stdx;

import des.gl.simple.meshobj;

import std.string;

///
class SceneLoader
{
    ///
    this( string fname )
    {
        if( !DerelictASSIMP3.isLoaded )
            DerelictASSIMP3.load();

        auto scene = aiImportFile( fname.toStringz, 0 );

        foreach( i; 0 .. scene.mNumMeshes )
            meshes ~= convMesh( scene.mMeshes[i] );
    }

    ///
    MeshData[] meshes;

    ///
    MeshData meshByName( string name, lazy MeshData def=null )
    {
        foreach( m; meshes )
            if( m.name == name ) return m;
        return def;
    }

protected:

    MeshData convMesh( in aiMesh* m )
    {
        auto ret = new MeshData;
        ret.name = toDStringFix( m.mName.data );

        auto cnt = m.mNumVertices;

        ret.vertices = getTypedArray!vec3( cnt,
                cast(void*)(m.mVertices) ).arr.dup;

        if( m.mNormals !is null )
            ret.normals = getTypedArray!vec3( cnt,
                    cast(void*)(m.mNormals) ).arr.dup;

        if( m.mTangents !is null )
            ret.tangents = getTypedArray!vec3( cnt,
                    cast(void*)(m.mTangents) ).arr.dup;

        if( m.mBitangents !is null )
            ret.bitangents = getTypedArray!vec3( cnt,
                    cast(void*)(m.mBitangents) ).arr.dup;

        foreach( i; 0 .. AI_MAX_NUMBER_OF_COLOR_SETS )
            if( m.mColors[i] !is null )
            {
                ret.colors ~= getTypedArray!vec4( cnt,
                        cast(void*)(m.mColors[i]) ).arr.dup;
            }

        foreach( i; 0 .. AI_MAX_NUMBER_OF_TEXTURECOORDS )
            if( m.mTextureCoords[i] !is null )
            {
                ret.texcrds ~= getTypedArray!vec3( cnt,
                        cast(void*)(m.mTextureCoords[i]) ).arr.dup;
                ret.texcrdsdims ~= m.mNumUVComponents[i];
            }

        foreach( i; 0 .. m.mNumFaces )
        {
            auto f = m.mFaces[i];
            ret.indices ~= getTypedArray!uint( f.mNumIndices,
                    cast(void*)f.mIndices ).arr;
        }

        return ret;
    }
}

