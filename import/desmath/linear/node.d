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

module desmath.linear.node;

public import desmath.linear.vector;
public import desmath.linear.matrix;

interface Node
{
    const @property
    {
        /+ local to parent transform +/
        mat4 self();
        const(Node) parent();

        final
        {
            vec3 x() { return vec3( self.col!(0).data[0 .. 3] ); }
            vec3 y() { return vec3( self.col!(1).data[0 .. 3] ); }
            vec3 z() { return vec3( self.col!(2).data[0 .. 3] ); }
            /+ in parent system +/
            vec3 pos() { return vec3( self.col!(3).data[0 .. 3] ); }
        }
    }
}

class Resolver
{
    mat4 opCall( const(Node) obj, const(Node) cam ) const
    {
        const(Node)[] obj_branch, cam_branch;
        obj_branch ~= obj;
        cam_branch ~= cam;

        while( obj_branch[$-1] )
            obj_branch ~= obj_branch[$-1].parent;
        while( cam_branch[$-1] )
            cam_branch ~= cam_branch[$-1].parent;

        top: 
        foreach( cbi, camparents; cam_branch )
            foreach( obi, objparents; obj_branch )
                if( camparents == objparents )
                {
                    cam_branch = cam_branch[0 .. cbi];
                    obj_branch = obj_branch[0 .. obi];
                    break top;
                }

        mat4 obj_mtr, cam_mtr;

        foreach( node; obj_branch )
            obj_mtr = node.self * obj_mtr;

        foreach( node; cam_branch )
            cam_mtr = cam_mtr * node.self.speedTransformInv;

        return cam_mtr * obj_mtr;
    }
}
