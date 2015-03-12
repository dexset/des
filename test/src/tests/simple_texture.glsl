//### vert
#version 430

layout(location=0) in vec3 vertex;
layout(location=1) in vec2 tcoord;

uniform mat4 fprj;
uniform mat4 camspace;

out Vertex { vec3 pos; vec3 uv; } vert;

vec3 tr( mat4 mtr, vec3 v, float point )
{ return ( mtr * vec4( v, point ) ).xyz; }

void main()
{
    gl_Position = fprj * vec4( vertex, 1.0 );

    vert.pos  = tr( camspace, vertex, 1.0 );
    vert.uv = tcoord;
}

//### frag
#version 430

in Vertex { vec3 pos; vec3 uv; } vert;

uniform sampler2DArray tex;
uniform uint layer;

out vec4 result;

void main()
{
    result = texture( tex, vec3(uv,layer) );
}
