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

module desgl.util.viewalgo;

public import desmath.linear;

import std.math;

mat4 lookAt( in vec3 pos, in vec3 to, in vec3 up )
{
    auto z = (pos-to).e;
    auto x = (up * z).e;
    vec3 y;
    if( x ) y = (z * x).e;
    else
    {
        y = (z * vec3(1,0,0)).e;
        x = (y * z).e;
    }
    return mat4([ x.x, y.x, z.x, pos.x,
                  x.y, y.y, z.y, pos.y,
                  x.z, y.z, z.z, pos.z,
                    0,   0,   0,     1 ]);
}

mat4 perspective(float fov, float aspect, float znear, float zfar)
{
    float xymax = znear * tan(fov * PI / 360.0);
    float ymin = -xymax;
    float xmin = -xymax;

    float width = xymax - xmin;
    float height = xymax - ymin;

    float depth = znear - zfar;
    float q = (zfar + znear) / depth;
    float dzn = 2.0 * znear;
    float qn = dzn * zfar / depth;

    float w = dzn / ( width * aspect );
    float h = dzn / height;

    return mat4([ w, 0,  0, 0,
                  0, h,  0, 0,
                  0, 0,  q, qn,
                  0, 0, -1, 0 ]);
}

mat4 ortho( sz_vec sz, z_vec z )
{
    float x = z.n - z.f;
    return mat4([ 2/sz.w, 0,      0,       0,
                  0,      2/sz.h, 0,       0,
                  0,      0,      -1/x,    0,
                  0,      0,      z.n/x,   1 ]);
}

mat4 ortho( float w, float h, float znear, float zfar )
{
    return ortho( sz_vec( w, h ), z_vec( znear, zfar ) );
}
