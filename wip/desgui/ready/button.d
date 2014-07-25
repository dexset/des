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

module desgui.ready.button;

import desgui.core.widget;
import desgui.core.label;
import desgui.core.reaction;

class DiButton : DiWidget
{
private:

    void changeStyle( string str )
    {
        switch( str )
        {
            case "active":
                break;
            case "":
                break;
            case "press":
                break;
            case "click":
                break;
            default:
                break;
        }
    }

    private void prepareStyles()
    {
        activate.connect({ changeStyle( "active" ); });
        release.connect({ changeStyle( "" ); });
        onPress.connect({ changeStyle( "press" ); });
        onClick.connect({ changeStyle( "click" ); });

        changeStyle( "" );
    }

public:

    mixin( ButtonReaction!SIGNALS );
    DiLabel label;

    this( DiWidget par, in irect rr, wstring str=""w, void delegate() onclick=null )
    {
        super( par );
        mixin( ButtonReaction!CONNECT );

        label = new DiLabel( this, irect(0,0,100,20), str );
        label.textAlign = label.TextAlign.CENTER;
        reshape.connect((r){ label.reshape( irect(0,0,rect.size) ); });

        if( onclick !is null ) onClick.connect( onclick );

        prepareStyles();

        reshape( rr );
    }
}
