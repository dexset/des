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

module desgui.core.draw;

public import desmath.linear.vector;
public import desil.rect;

import desil;

interface DiViewport
{
    @property irect rect() const;
    @property vec2 offset() const;
    @property vec2 scale() const;

    /++ перевод координат локальные +/
    final vec2 mapToLocal(T)( in T crd ) const 
        if( isCompVector!(2,float,T) )
    { 
        vec2 r = crd - rect.pos - offset;
        r.x /= scale.x;
        r.y /= scale.y;
        return r;
    }

    final vec2 mapToParent(T)( in T crd ) const
        if( isCompVector!(2,float,T) )
    {
        vec2 r = crd;
        r.x *= scale.x;
        r.y *= scale.y;
        return r + offset + rect.pos;
    }
}

interface DiDrawStack
{
    irect push( in DiViewport );
    void pull();
}

interface DiDrawable { void draw(); }
interface DiAnimate { void idle( float dt ); }

interface DiShapeDrawable : DiDrawable
{ void reshape( in irect ); }

interface DiNovemShapeDrawable : DiShapeDrawable
{
    @property
    {
        DiShapeDrawable[9] elems();
        ivec2 corner() const;
    }

    final void draw() 
    { foreach( e; elems ) if( e !is null ) e.draw(); }

    final void reshape( in irect r )
    {
        irect rect = r;

        if( rect.w < corner.x * 2 ) rect.w = corner.x * 2;
        if( rect.h < corner.y * 2 ) rect.h = corner.y * 2;

        if( elems[0] !is null ) elems[0].reshape( irect( rect.pos, corner ) );
        if( elems[1] !is null ) elems[1].reshape( irect( rect.pos.x + corner.x, rect.pos.y, rect.w - corner.x*2, corner.y ) );
        if( elems[2] !is null ) elems[2].reshape( irect( rect.pos.x + rect.w - corner.x, rect.pos.y, corner ) );

        if( elems[3] !is null ) elems[3].reshape( irect( rect.pos.x, rect.pos.y + corner.y, corner.x, rect.h - corner.y*2 ) );
        if( elems[4] !is null ) elems[4].reshape( irect( rect.pos + corner, rect.size - corner*2 ) );
        if( elems[5] !is null ) elems[5].reshape( irect( rect.pos.x + rect.w - corner.x, rect.pos.y + corner.y, corner.x, rect.h - corner.y*2 ) );

        if( elems[6] !is null ) elems[6].reshape( irect( rect.pos.x,                 rect.pos.y + rect.h - corner.y, corner ) );
        if( elems[7] !is null ) elems[7].reshape( irect( rect.pos.x + corner.x,          rect.pos.y + rect.h - corner.y, rect.w - corner.x*2, corner.y ) );
        if( elems[8] !is null ) elems[8].reshape( irect( rect.pos.x + rect.w - corner.x, rect.pos.y + rect.h - corner.y, corner ) );
    }
}

interface DiAnimateShape : DiShapeDrawable, DiAnimate 
{
    /* workaround Issue 11796 */
    void idle( float );
    void draw();
    void reshape( in irect ); 
}

interface DiDrawRect : DiShapeDrawable
{
    enum UseTexture
    {
        NONE = cast(int)0,
        ALPHA = 1,
        FULL = 2
    }

    @property
    {
        ref UseTexture useTexture();
        ref const(UseTexture) useTexture() const;

        irect rect() const;
        final void rect( in irect r ) { reshape( r ); }

        col4 color() const;
        void color( in col4 );
    }

    /* workaround Issue 11796 */
    void draw();
    void reshape( in irect ); 

    void image( in Image );
    void image( in ImageReadAccess );
}

//TODO: path, line, circle, etc

interface DiDrawFactory
{
    @property DiDrawRect rect();
    //TODO: path, line, circle, etc
}
