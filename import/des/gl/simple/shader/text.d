module des.gl.simple.shader.text;

import des.gl.base;

enum SS_WIN_TEXT = 
`//### vert
#version 120
uniform vec2 winsize;

attribute vec2 pos;
attribute vec4 color;
attribute vec2 uv;

varying vec2 ex_uv;
varying vec4 ex_color;

void main(void)
{
    gl_Position = vec4( 2.0 * vec2(pos.x, -pos.y) / winsize + vec2(-1.0,1.0), 0, 1 );
    ex_uv = uv;
    ex_color = color;
}
//### frag
#version 120
uniform sampler2D ttu;

varying vec2 ex_uv;
varying vec4 ex_color;

void main(void) 
{ 
    gl_FragColor = texture2D( ttu, ex_uv ) * ex_color;
}`;
