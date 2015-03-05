module des.assimp.generator;

import des.util.logsys;
import des.util.stdext.algorithm;

import des.assimp.mesh;

///
class SMUniformSurfaceMeshGenerator
{
    mixin ClassLogger;
protected:

    ///
    vec2[] planeCoords( uivec2 res )
    {
        vec2[] ret;

        float sx = 1.0 / res.x;
        float sy = 1.0 / res.y;

        foreach( y; 0 .. res.y+1 )
            foreach( x; 0 .. res.x+1 )
                ret ~= vec2( sx * x, sy * y );

        return ret;
    }

    ///
    uint[] triangleStripPlaneIndex( uivec2 res, uint term=uint.max )
    {
        uint[] ret;
        foreach( y; 0 .. res.y-1 )
        {
            ret ~= [ y*res.x, (y+1)*res.x ];
            foreach( x; 1 .. res.x )
                ret ~= [ y*res.x+x, (y+1)*res.x+x ];
            ret ~= term;
        }
        return ret;
    }

    abstract
    {
        vec3[] transformCoords( vec2[] );
        vec2[] transformTexCoords( vec2[] );
        mat3[] getTangentSpace( vec2[] );
    }

public:

    this() { logger = new InstanceLogger( this ); }

    uivec2 subdiv;

    SMMesh getMesh( string name )
    {
        scope(exit) logger.Debug( "generate mesh '%s'" );

        auto crd = planeCoords( subdiv );

        SMMesh m;

        m.name = name;
        m.type = m.Type.TRIANGLE_STRIP;
        m.indices = triangleStripPlaneIndex( subdiv+uivec2(1,1) );
        m.vertices = transformCoords( crd );
        m.texcoords = [ SMTexCoord( 2, cast(float[])transformTexCoords( crd ) ) ];

        auto ts = getTangentSpace( crd );

        m.normals = amap!(a=>vec3(a.col(2)))( ts );
        m.tangents = amap!(a=>vec3(a.col(0)))( ts );
        m.bitangents = amap!(a=>vec3(a.col(1)))( ts );
        m.colors = null;

        return m;
    }
}

//vec3 cylinder( in vec2 c ) pure
//{ return vec3( cos(c.x), sin(c.x), c.y ); }

class SMSphereMeshGenerator : SMUniformSurfaceMeshGenerator
{
protected:

    import std.math;

    vec3 spheric( in vec2 c ) pure
    { return vec3( cos(c.x) * sin(c.y), sin(c.x) * sin(c.y), cos(c.y) ); }

    vec2[] truePos( vec2[] crd )
    { return amap!( a => a * vec2(PI*2,PI) )( crd ); }

    mat3 tangentSpace( in vec2 c )
    {
        auto t = vec3( cos(c.x), sin(c.x), 0 );
        auto n = vec3( cos(c.x) * sin(c.y), sin(c.x) * sin(c.y), cos(c.y) );
        return mat3( t,-cross(t,n),n ).T;
    }

    override
    {
        vec3[] transformCoords( vec2[] crd )
        { return amap!( a => spheric(a) * radius )( truePos( crd ) ); }

        vec2[] transformTexCoords( vec2[] crd ) { return crd; }

        mat3[] getTangentSpace( vec2[] crd )
        { return amap!( a => tangentSpace(a) )( truePos( crd ) ); }
    }

public:

    this( float R, uint rx, uint ry )
    {
        subdiv = uivec2(rx,ry);
        radius = R;
    }

    float radius;
}

SMMesh smGetSphereMesh( string name, float R, uint rx, uint ry )
{
    auto gen = new SMSphereMeshGenerator( R, rx, ry );
    return gen.getMesh( name );
}
