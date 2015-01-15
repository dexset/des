/// Event processor definitions
module des.app.evproc;

import std.conv : to;

import des.util.arch;
import derelict.sdl2.sdl;

import des.util.logsys;
import des.util.stdext.string;

public import des.app.event;

/// 
interface SDLEventProcessor : DesBase
{
    /++ process SDL event
     + Returns:
     + `true` if processed
     + `false` otherwise
     +/
    bool procSDLEvent( in SDL_Event ev );
}

///
abstract class BaseSDLEventProcessor : SDLEventProcessor
{
    mixin DES;
    this() { prepareDES(); }
}

///
class MouseEventProcessor : BaseSDLEventProcessor
{
    mixin DES;
protected:
    MouseEvent main_event;

public:
    ///
    Signal!( in_MouseEvent ) signal;

    ///
    alias signal this;

    ///
    MouseEvent lastState() const @property { return main_event; }

    bool procSDLEvent( in SDL_Event ev )
    {
        switch( ev.type )
        {
            case SDL_MOUSEMOTION:
                auto e = ev.motion;
                main_event.type = MouseEvent.Type.MOTION;
                main_event.btn = MouseEvent.Button.NONE;
                main_event.pos = ivec2( e.x, e.y );
                main_event.rel = ivec2( e.xrel, e.yrel );

                foreach( i, btn; [EnumMembers!(MouseEvent.Button)][1..$] )
                {
                    if( binHas( main_event.mask, btn ) )
                        main_event.relPress[i] = main_event.pos - main_event.posPress[i];
                    else
                    {
                        main_event.posPress[i] = main_event.pos;
                        main_event.relPress[i] = ivec2(0,0);
                    }
                }
                signal( main_event );
                return true;
            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP:
                auto e = ev.button;
                main_event.btn = cast(MouseEvent.Button)SDL_BUTTON(e.button);
                if( e.state == SDL_PRESSED )
                {
                    main_event.type = MouseEvent.Type.PRESSED;
                    main_event.appendButton( SDL_BUTTON(e.button) );
                    main_event.posPress[main_event.buttonIndex(main_event.btn)] = main_event.pos;
                }
                else
                {
                    main_event.type = MouseEvent.Type.RELEASED;
                    main_event.removeButton( SDL_BUTTON(e.button) );
                }
                signal( main_event );
                return true;
            case SDL_MOUSEWHEEL:
                auto e = ev.wheel;
                main_event.type = MouseEvent.Type.WHEEL;
                main_event.btn = MouseEvent.Button.NONE;
                main_event.whe = ivec2( e.x, e.y );
                signal( main_event );
                return true;
            default: return false;
        }
    }
}

///
class WindowEventProcessor : BaseSDLEventProcessor
{
    mixin DES;
    ///
    Signal!() shown;
    ///
    Signal!() hidden;
    ///
    Signal!() exposed;
    ///
    Signal!(ivec2) moved;
    ///
    Signal!(ivec2) resized;
    ///
    Signal!() minimized;
    ///
    Signal!() maximized;
    ///
    Signal!() restored;
    ///
    Signal!() enter;
    ///
    Signal!() leave;
    ///
    Signal!() focusGained;
    ///
    Signal!() focusLost;
    ///
    Signal!() close;
    
    bool procSDLEvent( in SDL_Event ev )
    {
        if( ev.type != SDL_WINDOWEVENT ) return false;
        auto wID = ev.window.windowID;
        auto data = ivec2( ev.window.data1, ev.window.data2 );

        switch(ev.window.event)
        {
            case SDL_WINDOWEVENT_SHOWN:        shown();         break;
            case SDL_WINDOWEVENT_HIDDEN:       hidden();        break;
            case SDL_WINDOWEVENT_EXPOSED:      exposed();       break;
            case SDL_WINDOWEVENT_MOVED:        moved( data );   break;
            case SDL_WINDOWEVENT_RESIZED:      resized( data ); break;
            case SDL_WINDOWEVENT_MINIMIZED:    minimized();     break;
            case SDL_WINDOWEVENT_MAXIMIZED:    maximized();     break;
            case SDL_WINDOWEVENT_RESTORED:     restored();      break;
            case SDL_WINDOWEVENT_ENTER:        enter();         break;
            case SDL_WINDOWEVENT_LEAVE:        leave();         break;
            case SDL_WINDOWEVENT_FOCUS_GAINED: focusGained();   break;
            case SDL_WINDOWEVENT_FOCUS_LOST:   focusLost();     break;
            case SDL_WINDOWEVENT_CLOSE:        close();         break;
            default: return false;
        }
        return true;
    }
}

///
class KeyboardEventProcessor : BaseSDLEventProcessor
{
    mixin DES;
    ///
    Signal!( in_KeyboardEvent ) signal;

    ///
    alias signal this;

    bool procSDLEvent( in SDL_Event ev )
    {
        switch( ev.type )
        {
            case SDL_KEYUP:
            case SDL_KEYDOWN:
                with( ev.key )
                {
                    auto rep = cast(bool)repeat;
                    auto pre = cast(bool)state;
                    auto cod = cast(KeyboardEvent.Scan)keysym.scancode;
                    auto sym = keysym.sym;
                    auto mod = cast(KeyboardEvent.Mod)keysym.mod;
                    signal( KeyboardEvent( pre, rep, cod, sym, mod ) );
                }
                return true;
            default: return false;
        }
    }
}

///
class TextEventProcessor : BaseSDLEventProcessor
{
    mixin DES;
    ///
    Signal!( dstring ) input;
    ///
    Signal!( dstring, int, int ) edit;

    bool procSDLEvent( in SDL_Event ev )
    {
        switch( ev.type )
        {
            case SDL_TEXTINPUT:
                with( ev.text )
                    input( to!dstring( text.toDStringFix ) );
                return true;
            case SDL_TEXTEDITING:
                with( ev.edit )
                    edit( to!dstring( text.toDStringFix ), start, length );
                return true;
            default: return false;
        }
    }
}
