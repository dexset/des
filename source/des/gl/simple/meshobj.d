module des.gl.simple.meshobj;

import des.math.linear;
import des.log;
import des.gl.simple.object;
import des.stdx.algorithm;

///
class MeshData
{
    ///
    string name;
    ///
    vec3[] vertices;
    ///
    vec3[] normals, tangents, bitangents;
    ///
    vec4[][] colors;
    ///
    vec3[][] texcrds;
    ///
    uint[] texcrdsdims;
    ///
    uint[] indices;
}

///
class GLMeshObject : GLSimpleObject
{
protected:

    ///
    MeshData mesh_data;

    ///
    GLBuffer vertices;
    ///
    GLBuffer normals, tangents, bitangents;
    ///
    GLBuffer[] colors;
    ///
    GLBuffer[] texcrds;
    ///
    GLBuffer indices;

    ///
    abstract void prepareAttribPointers();

public:

    ///
    this( string shader_source, MeshData md )
    in{ assert( md !is null ); } body
    {
        super( shader_source );
        mesh_data = md;
        prepareBuffers();
        prepareAttribPointers();
    }

    ///
    this( CommonGLShaderProgram sh, MeshData md )
    in
    {
        assert( sh !is null );
        assert( md !is null );
    }
    body
    {
        super( sh );
        mesh_data = md;
        prepareBuffers();
        prepareAttribPointers();
    }

protected:

    ///
    void prepareBuffers()
    {
        logger.info( "work with mesh '%s'", mesh_data.name );

        vertices = createArrayBuffer();
        vertices.setData( mesh_data.vertices );

        logger.trace( "vertices: ", mesh_data.vertices.length );

        if( mesh_data.normals.length )
        {
            normals = newEMM!GLBuffer();
            normals.setData( mesh_data.normals );
            logger.trace( "with normals" );
        }

        if( mesh_data.tangents.length )
        {
            tangents = newEMM!GLBuffer();
            tangents.setData( mesh_data.tangents );
            logger.trace( "with tangents" );
        }

        if( mesh_data.bitangents.length )
        {
            bitangents = newEMM!GLBuffer();
            bitangents.setData( mesh_data.bitangents );
            logger.trace( "with bitangents" );
        }

        foreach( i; 0 .. mesh_data.colors.length )
        {
            auto cbuf = newEMM!GLBuffer();
            cbuf.setData( mesh_data.colors[i] );
            colors ~= cbuf;
            logger.trace( "with colors %d", i );
        }

        foreach( i; 0 .. mesh_data.texcrds.length )
        {
            auto tbuf = newEMM!GLBuffer();
            switch( mesh_data.texcrdsdims[i] )
            {
                case 1:
                    tbuf.setData( amap!(a=>a.x)( mesh_data.texcrds[i] ) );
                    break;
                case 2:
                    tbuf.setData( amap!(a=>a.xy)( mesh_data.texcrds[i] ) );
                    break;
                case 3:
                    tbuf.setData( mesh_data.texcrds[i] );
                    break;
                default:
                    throw new Exception( "WTF?: texture coordinate dims == " ~ 
                            to!string( mesh_data.texcrdsdims[i] ) );
            }
            texcrds ~= tbuf;
            logger.trace( "with texcrds %d (%dD)", i, mesh_data.texcrdsdims[i] );
        }

        if( mesh_data.indices.length )
        {
            indices = createIndexBuffer();
            indices.setData( mesh_data.indices );

            logger.trace( "with indices" );
        }
    }
}
