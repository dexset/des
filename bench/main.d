import std.stdio;
import std.datetime;

import desmath;
import desgl.util.viewalgo;

class Camera : Node
{
    Resolver rsl;
    mat4 mtr, prj;

    this() 
    { 
        rsl = new Resolver; 
        prj = perspective( 72, 4.0 / 3.0, 0.2, 100 );
    }

    mat4 opCall( Node obj )
    { return prj * rsl( obj, this ); }

    @property 
    {
        mat4 self() const { return mtr; }
        Node parent() { return null; }
    }
}

class Obj : Node
{
    mat4 mtr;
    @property 
    {
        mat4 self() const { return mtr; }
        Node parent() { return null; }
    }
}

void main() 
{
    auto cam = new Camera;
    auto obj = new Obj;

    void f0()
    {
        auto pnt = vec3( 1, 2, 3 ); 
        auto buf = cam(obj) * vec4(pnt,1);
        auto res = buf.xyz / buf.w;
    }
    enum n = 500_000;
    auto res = benchmark!(f0)(n);

    foreach( i, r; res )
    {
        writefln("Milliseconds to call fun[%d] %s times: %s", i, n, r.msecs);
    }
}
