//### vert
#version 430

layout(location=0) in vec3 vertex;

uniform mat4 fprj;

out vec3 uvCube;

void main()
{
    gl_Position = fprj * vec4( vertex, 1.0 );
    uvCube = vertex;
}

//### frag
#version 430

in vec3 uvCube;

uniform samplerCube texCM;

out vec4 result;

void main()
{
    vec3 clr = texture( texCM, uvCube ).xyz;
    result = vec4( clr.xy, clr.z + .1, 1 );
}
