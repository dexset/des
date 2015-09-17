module des.gl.simple.shader.text;

import des.gl.base;

enum SS_WIN_TEXT = 
`//### vert
#version 120
attribute vec2 vert;
attribute vec2 uv;

uniform ivec2 win_size;

varying vec2 ex_uv;

void main(void)
{
    vec2 tr_vert = vert / win_size * 2 - 1;
    gl_Position = vec4( tr_vert.x, -tr_vert.y, 0, 1);
    ex_uv = uv;
}
//### frag
#version 120
uniform sampler2D ttu;
uniform vec3 color;

varying vec2 ex_uv;

void main(void) 
{ 
    gl_FragColor = vec4( color, texture2D( ttu, ex_uv ).r );
}`;
