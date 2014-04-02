module desgl.ready.shaders;

public import desgl.base.shader;

enum ShaderSource SS_SIMPLE = 
{
`#version 120
attribute vec3 vertex;
attribute vec4 color;
varying vec4 v_color;
void main(void) 
{ 
    gl_Position = vec4( vertex, 1 ); 
    v_color = color;
}`, 
`#version 120
varying vec4 v_color;
void main(void) { gl_FragColor = v_color; } `
};

enum ShaderSource SS_WINCRD_UNIFORMCOLOR = 
{
`#version 120
uniform vec2 winsize;
attribute vec2 vertex;
void main(void)
{
    gl_Position = vec4( 2.0 * vec2(vertex.x, -vertex.y) / winsize + vec2(-1.0,1.0), -0.05, 1 );
}`, 
`#version 120
uniform vec4 color;
void main(void) { gl_FragColor = color; } `
};

/++
    uniform vec2 winsize - размер окна

    attribute vec2 vertex - позиция в системе координат окна
    attribute vec4 color - цвет вершины
    attribute vec2 uv - текстурная координата

    uniform sampler2D ttu - текстурный сэмплер
    uniform int use_texture - флаг использования текстуры: 
                                0 - не использовать,
                                1 - использовать только альфу
                                2 - использовать все 4 канала текстуры

 +/
enum ShaderSource SS_WINCRD_FULLCOLOR_TEXTURE = 
{
`#version 120
uniform vec2 winsize;

attribute vec2 vertex;
attribute vec4 color;
attribute vec2 uv;

varying vec2 ex_uv;
varying vec4 ex_color;

void main(void)
{
    gl_Position = vec4( 2.0 * vec2(vertex.x, -vertex.y) / winsize + vec2(-1.0,1.0), -0.05, 1 );
    ex_uv = uv;
    ex_color = color;
}
`,

`#version 120
uniform sampler2D ttu;
uniform int use_texture;

varying vec2 ex_uv;
varying vec4 ex_color;

void main(void) 
{ 
    if( use_texture == 0 )
        gl_FragColor = ex_color; 
    else if( use_texture == 1 )
        gl_FragColor = vec4( 1, 1, 1, texture2D( ttu, ex_uv ).r ) * ex_color;
    else if( use_texture == 2 )
        gl_FragColor = texture2D( ttu, ex_uv );
}`
};
