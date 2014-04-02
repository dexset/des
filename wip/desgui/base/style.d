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

module desgui.base.style;

import desgui.core.style;

import desgui.base.gldraw;

struct DiColorSmoothChange
{
    float speed = 2;
    col4 cur = col4(0,0,0,0),
         trg = col4(0,0,0,0);

    void idle( float dt )
    {
        if( dt * speed > 1.0f ) speed = 1.0 / dt;
        cur += ( trg - cur ) * speed * dt;
    }
}

class DiBaseSubstrate : DiSubstrate
{
    DiGLDrawRect dr;
    DiColorSmoothChange csc;

    col4 active = col4( .3, .3, .4, .4 ),
         base = col4( .2, .2, .3, .3 );

    this()
    {
        dr = new DiGLDrawRect;
        changeStyle("");
    }

    void idle( float dt )
    {
        csc.idle( dt );
        dr.color = csc.cur;
    }

    void draw() { dr.draw(); }
    void reshape( in irect r ) { dr.reshape( r ); }
    void changeStyle( string st )
    {
        switch( st )
        {
            case "active": csc.trg = active; break;
            default: csc.trg = base; break;
        }
    }
}

class DiButtonSubstrate : DiBaseSubstrate
{
    col4 press = col4( .8, .9, .5, .8 );

    this()
    {
        super();
        active = col4( .4, .5, .6, .7 );
        base = col4( .3, .3, .3, .5 );
    }

    override void changeStyle( string st )
    {
        csc.speed = 2;
        switch( st )
        {
            case "active": csc.trg = active; break;
            case "press": csc.trg = press; csc.speed = 250; break;
            case "click": csc.trg = active; csc.speed = 1; break;
            default: csc.trg = base; break;
        }
    }
}

class DiBaseStyle : DiStyle
{
    DiSubstrate getSubstrate( string name )
    {
        switch( name )
        {
            case "button": return new DiButtonSubstrate();
            default: return new DiBaseSubstrate();
        }
    }
}
