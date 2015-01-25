//### vert
#version 330

in vec4 pos;

uniform mat4 prj;

void main() { gl_Position = prj * pos; }

//### frag
#version 330

uniform vec4 col;
out vec4 color;

void main() { color = col; }
