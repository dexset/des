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

module desgui.core.panel;

public import desgui.core.widget;
import desgui.core.draw;

class DiPanelException: DiWidgetException
{ 
    @safe pure nothrow 
    this( string msg, string file=__FILE__, int ln=__LINE__ ) 
    { super( msg, file, ln ); } 
}

class DiPanel : DiWidget
{
protected:
    DiSubstrate substrate;

public:

    this( DiWidget par )
    {
        super( par );

        draw.connect(
        { 
            if( substrate !is null ) 
                substrate.draw(); 
        });

        reshape.connect((r)
        { 
            if( substrate !is null ) 
                substrate.reshape( irect(0,0,rect.size) ); 
        });

        import desutil.timer;
        auto timer = new Timer;
        idle.connect(
        {
            if( substrate !is null )
                substrate.idle( timer.cycle() );
        });

        changeStyle.connect( (st)
        {
            if( substrate !is null )
                substrate.changeStyle( st );
        });

        setSubstrate( ctx.style.getSubstrate("") );
    }

    this( DiWidget par, in irect rr, DiSubstrate ss )
    {
        this( par );
        setSubstrate( ss );
        reshape( rr );
    }

    void setSubstrate( DiSubstrate ss ) { substrate = ss; }
}
