module draw;

import std.math;

import des.math.linear;
import des.util.stdext.algorithm;
import des.util.helpers;

import des.space;

import des.gl;

class Sphere : GLSimpleObject, SpaceNode
{
    mixin SpaceNodeHelper;

protected:

    GLBuffer pos, ind;

    void prepareBuffers()
    {
        auto loc = shader.getAttribLocations( "pos" );
        pos = createArrayBuffer;
        ind = createIndexBuffer;
        setAttribPointer( pos, loc[0], 3, GLType.FLOAT );

        vec3[] buf;

        vec3 sp( vec2 a, float R ) { return spheric(a) * R; }
        vec3 cl( vec2 a, float R ) { return cylinder(a) * vec3(R,R,1); }

        buf ~= amap!(a=>a+vec3(0,0,0))( amap!(a=>sp(a,R))( planeCoord( uivec2( resU, resV/2 ), vec2(0,PI*2), vec2(PI,PI/2) ) ) );
        buf ~= amap!(a=>a-vec3(0,0,0))( amap!(a=>sp(a,R*0.9))( planeCoord( uivec2( resU, resV/2 ), vec2(0,PI*2), vec2(PI/2,PI) ) ) );

        pos.setData( buf );

        ind.setData( triangleStripPlaneIndex( uivec2( resU+1, resV+2 ), uint.max ) );
    }

    uint resU, resV;
    float R;

public:

    this( float r, uint u, uint v )
    {
        R = r;
        resU = u;
        resV = v;
        import std.file;
        super( newEMM!CommonGLShaderProgram(
                parseGLShaderSource(
                    readText(
                        appPath( "..", "data", "shaders", "object.glsl" )
                    ))));
        prepareBuffers();
    }

    void draw( Camera cam )
    {
        shader.setUniform!col4( "col", col4(1,0,0,1) );
        glEnable( GL_PRIMITIVE_RESTART );
        glPrimitiveRestartIndex(uint.max);
        glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
        shader.setUniform!mat4( "prj", cam.projection.matrix * cam.resolve(this) );
        drawElements( DrawMode.TRIANGLE_STRIP );
        glDisable( GL_PRIMITIVE_RESTART );
    }
}

vec2[] planeCoord( uivec2 res, vec2 x_size=vec2(0,1), vec2 y_size=vec2(0,1) )
{
    vec2[] ret;

    float sx = (x_size[1] - x_size[0]) / res.u;
    float sy = (y_size[1] - y_size[0]) / res.v;

    foreach( y; 0 .. res.y+1 )
        foreach( x; 0 .. res.x+1 )
            ret ~= vec2( x_size[0] + sx * x, y_size[0] + sy * y );

    return ret;
}

vec3 spheric( in vec2 c ) pure
{ return vec3( cos(c.x) * sin(c.y), sin(c.x) * sin(c.y), cos(c.y) ); }

vec3 cylinder( in vec2 c ) pure
{ return vec3( cos(c.x), sin(c.x), c.y ); }

uint[] triangleStripPlaneIndex( uivec2 res, uint term )
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
