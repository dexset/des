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

module desgui.core.reaction;

enum { CONNECT, SIGNALS }

@property string ButtonReaction( uint type )()
{
    static if( type == CONNECT )
    {
        return `
        {
            static assert( is(typeof(this): DiWidget), "button reaction avail only for DiWidget");

            bool _buttonreaction_prepare = 0;
            mouse.connect( ( in ivec2 p, in DiMouseEvent me )
            {
                if( me.type == me.Type.RELEASED )
                {
                    if( _buttonreaction_prepare && vec2(p-rect.pos) in activeArea )
                        onClick();
                    _buttonreaction_prepare = 0;
                    focus = 0;
                }
                else if( me.type == me.Type.PRESSED )
                {
                    _buttonreaction_prepare = 1;
                    focus = 1;
                    onPress();
                }
            });
            release.connect({ _buttonreaction_prepare = 0; });

            processEventMask |= EventCode.MOUSE;
        }`;
    }
    else if( type == SIGNALS )
    {
        return `EmptySignal onClick, onPress;`;
    }
}

unittest
{
    import desgui.core.widget;
    import desmath.types.vector;
    import desmath.types.rect;

    class DiButton : DiWidget
    {
    public:
        mixin( ButtonReaction!SIGNALS );

        this()
        {
            super( new TestContext );
            mixin( ButtonReaction!CONNECT );
            reshape( irect(0,0,10,10) );
        }
    }

    auto btn = new DiButton;
    bool click = false;
    bool press = false;
    btn.onClick.connect({ click = true; });
    btn.onPress.connect({ press = true; });
    assert( !press );
    assert( !click );
    btn.mouse( ivec2( 5,5 ), DiMouseEvent( DiMouseEvent.Type.PRESSED, 1 ) );
    assert(  press );
    assert( !click );
    btn.mouse( ivec2( 5,5 ), DiMouseEvent( DiMouseEvent.Type.RELEASED, 1 ) );
    assert(  press );
    assert(  click );
}
