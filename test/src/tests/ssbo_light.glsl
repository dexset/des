//### vert
#version 430

layout(location=0) in vec3 vertex;
layout(location=1) in vec3 normal;

uniform mat4 fprj;
uniform mat4 camspace;

out Vertex { vec3 pos; vec3 norm; } vert;

vec3 tr( mat4 mtr, vec3 v, float point )
{ return ( mtr * vec4( v, point ) ).xyz; }

void main()
{
    gl_Position = fprj * vec4( vertex, 1.0 );

    vert.pos  = tr( camspace, vertex, 1.0 );
    vert.norm = tr( camspace, normal, 0.0 );
}

//### frag
#version 430

in Vertex { vec3 pos; vec3 norm; } vert;

struct Light
{
    vec3 pos;
    int type;
    mat4 cs2local;
    vec3 color;
    float intensity;
    float attenuation;
    float type_data[7];
};

float sat( float val ) { return max( 0, min( 1, val ) ); }

float calcAttenuation( float dist, float inner, float outer )
{
    float d = max( dist, inner );
    return sat( 1.0 - pow( d / outer, 4.0 ) ) / ( d * d + 1.0 );
}

/// diffuse, specular
vec3[2] calcLight( Light ll, vec3 pos, vec3 norm, float spow )
{
    vec3[2] ret;
    ret[0] = vec3(0);
    ret[1] = vec3(0);

    if( ll.type < 0 ) return ret;

    vec3 lvec = ll.pos - pos;
    float ldst = length( lvec );

    float atten = calcAttenuation( ldst, 0.1, ll.attenuation ) * ll.intensity;
    if( atten <= 0.001 ) return ret;

    vec3 ldir = normalize( lvec );
    float visible = 1.0;

    float nxdir = max( 0.0, dot( norm, ldir ) );

    ret[0] = ll.color * nxdir * atten * visible;

    if( nxdir > 0 )
    {
        vec3 cvec = normalize( -pos );
        vec3 hv = normalize( lvec + cvec );
        float nxhalf = max( 0.0, dot( norm, hv ) );
        ret[1] = ll.color * pow( nxhalf, pow( 2, 10*spow+1 ) ) * atten * visible;
    }

    return ret;
}

layout(std430,binding=2) buffer LightBuffer
{
    Light light[];
};

uniform vec4 diffuse;

out vec4 result;

void main()
{
    vec4 ambient  = vec4( vec3(0.02), 1 );
    vec4 specular = vec4( vec3(0.5), 1 );

    vec3[2] rs;
    rs[0] = vec3(0);
    rs[1] = vec3(0);

    int lcnt = light.length();

    for( int i = 0; i < lcnt; i++ )
    {
        vec3[2] buf = calcLight( light[i], vert.pos, normalize( vert.norm ), 0.2f );
        rs[0] += buf[0];
        rs[1] += buf[1];
    }

    result = ambient +
             diffuse * vec4( rs[0], 1 ) +
             specular * vec4( rs[1], 1 );
}
