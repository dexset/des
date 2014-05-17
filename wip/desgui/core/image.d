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

module desgui.core.image;

import desgui.core.widget;
import desil;

class DiImageException : DiException
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

class DiImage : DiWidget
{
protected:
    DiDrawRect plane;
    AspectRatio asprat;
    imsize_t tc;
    LineAlign px = LineAlign.CENTER, py = LineAlign.CENTER;
public:

    enum AspectRatio { IGNORE, FIT, EXPAND }
    enum LineAlign { START, END, CENTER }

    this( DiWidget par, in irect r )
    {
        super( par );

        plane = ctx.draw.rect();
        plane.useTexture = plane.UseTexture.FULL;

        reshape.connect( (r) 
        {
            ivec2 t_size, t_pos;

            float imratio = tc.h / cast(float)(tc.w);
            float wiratio = rect.h / cast(float)(rect.w);

            final switch( asprat )
            {
                case AspectRatio.IGNORE:
                    t_size = rect.size;
                    break;
                case AspectRatio.FIT:
                    if( wiratio > imratio )
                        t_size = ivec2( rect.w, rect.w * imratio );
                    else
                        t_size = ivec2( rect.h / imratio, rect.h );
                    break;
                case AspectRatio.EXPAND:
                    if( wiratio < imratio )
                        t_size = ivec2( rect.w, rect.w * imratio );
                    else
                        t_size = ivec2( rect.h / imratio, rect.h );
                    break;
            }

            final switch( px )
            {
                case LineAlign.START: t_pos.x = 0; break;
                case LineAlign.CENTER: t_pos.x = ( rect.w - t_size.x ) / 2; break;
                case LineAlign.END: t_pos.x = rect.w - t_size.x; break;
            }

            final switch( py )
            {
                case LineAlign.START: t_pos.y = 0; break;
                case LineAlign.CENTER: t_pos.y = ( rect.h - t_size.y ) / 2; break;
                case LineAlign.END: t_pos.y = rect.h - t_size.y; break;
            }

            plane.reshape( irect( t_pos, t_size ) );
        });

        draw.connect({ plane.draw(); });

        reshape( r );
    }

    this( DiWidget par, in irect r, in Image im )
    {
        this( par, r );
        image( im );
    }

    this( DiWidget par, in irect r, in ImageReadAccess ira )
    {
        this( par, r );
        image( ira );
    }

    void image( in Image im ) 
    {
        plane.image( im ); 
        tc = im.size;
        reshape( rect );
    }

    void image( in ImageReadAccess ira ) 
    {
        plane.image( ira ); 
        tc = ira.size;
        reshape( rect );
    }

    @property
    {
        AspectRatio aspectRatio() const { return asprat; }
        void aspectRatio( AspectRatio val ){ asprat = val; reshape(rect); }

        LineAlign alignX() const { return px; }
        LineAlign alignY() const { return py; }
        void alignX( LineAlign val ){ px = val; reshape( rect ); }
        void alignY( LineAlign val ){ py = val; reshape( rect ); }
    }
}
