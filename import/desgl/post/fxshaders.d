/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

module desgl.post.fxshaders;

public import desgl.base.shader;

enum ShaderSource SS_WINSZ_SIMPLE_FBO_FX = 
{
`#version 120
uniform vec2 winsize;
attribute vec2 vertex;
attribute vec2 uv;
varying vec2 ex_uv;
void main(void)
{
    gl_Position = vec4( 2.0 * vec2(vertex.x, vertex.y) / winsize + vec2(-1.0,-1.0), 0, 1 );
    ex_uv = uv;
}`,
`#version 120
uniform vec2 winsize;
uniform sampler2D ttu;
varying vec2 ex_uv;
void main(void)
{
    vec4 sum = vec4(0);

    int dw = 4;
    int dh = 4;

    float c = 0.3f;

    float xs = 1.0f / winsize.x;
    float ys = 1.0f / winsize.y;

    for( int i = -dw+1; i < dw; i++ )
    {
        for( int j = -dh+1; j < dh; j++ )
        {
            float k = c / ( i*i + j*j + c );
            vec4 clr = texture2D( ttu, ex_uv + vec2( i*xs, j*ys ) );
            sum +=  clr * k;
        }
    }

    float accum = 0;
    if( sum.x > 1 ) { accum += sum.x - 1; sum.x = 1; }
    if( sum.y > 1 ) { accum += sum.y - 1; sum.y = 1; }
    if( sum.z > 1 ) { accum += sum.z - 1; sum.z = 1; }

    vec4 res = ( sum / ( accum + 2.0f ) + vec4(1,1,1,0) * accum );
    gl_FragColor = res;
    //gl_FragColor = vec4( res.xyz, res.w * length(res.xyz) );
}`
};

enum ShaderSource SS_WINSZ_SIMPLE_FBO = 
{
`#version 120
uniform vec2 winsize;
attribute vec2 vertex;
attribute vec2 uv;
varying vec2 ex_uv;
void main(void)
{
    gl_Position = vec4( 2.0 * vec2(vertex.x, vertex.y) / winsize + vec2(-1.0,-1.0), 0, 1 );
    ex_uv = uv;
}`,
`#version 120
uniform sampler2D ttu;
uniform float coef;
varying vec2 ex_uv;
void main(void)
{
    vec4 res = texture2D( ttu, ex_uv );
    res.xyz *= coef;
    float kk = 1;
    float rl = length(res.xyz);
    float vv = 0.05;
    if( rl < vv ) kk -= vv + rl;
    res.w *= kk;
    gl_FragColor = res;
}`
};
