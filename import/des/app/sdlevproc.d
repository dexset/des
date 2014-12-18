module des.app.sdlevproc;

public import derelict.sdl2.sdl;

public import des.app.event;

public import des.math.linear.vector;

import std.string;
import std.range;
import std.traits;

import des.util.stdext.string;
import des.util.arch;

class AppEventProcException : Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

/+
class EventProcessor : DesObject //Возвращает true, если событие было обработано
{ bool opCall( const ref SDL_Event ); }

class MouseEventProcessor : EventProcessor
{
    mixin DES;
private:
    MouseEvent main_event;
public:
    alias ref const(MouseEvent) in_MouseEvent;
    Signal!( in_MouseEvent ) mouse;

    override bool opCall( const ref SDL_Event ev )
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
                mouse( main_event );
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
                mouse( main_event );
            return true;
            case SDL_MOUSEWHEEL:
                auto e = ev.wheel;
                main_event.type = MouseEvent.Type.WHEEL;
                main_event.btn = MouseEvent.Button.NONE;
                main_event.whe = ivec2( e.x, e.y );
                mouse( main_event );
            return true;
            default: return false;
        }
    }
}

class KeyboardEventProcessor : EventProcessor
{
    mixin DES;

    Signal!( const(KeyboardEvent) ) key;

    override bool opCall( const ref SDL_Event ev )
    {
        switch( ev.type )
        {
            case SDL_KEYUP:
            case SDL_KEYDOWN:
                key( convertEvent( ev ) );
                return true;
            default: return false;
        }
    }

    KeyboardEvent convertEvent( const ref SDL_Event ev )
    {
        auto rep = cast(bool)ev.key.repeat;
        auto pre = cast(bool)ev.key.state;
        auto cod = cast(KeyboardEvent.Scan)ev.key.keysym.scancode;
        auto sym = ev.key.keysym.sym;
        auto mod = cast(KeyboardEvent.Mod)ev.key.keysym.mod;
        return KeyboardEvent( pre, rep, cod, sym, mod );
    }
}

class WindowEventProcessor : EventProcessor
{
    mixin DES;
    Signal!() shown;
    Signal!() hidden;
    Signal!() exposed;
    Signal!(ivec2) moved;
    Signal!(ivec2) resized;
    Signal!() minimized;
    Signal!() maximized;
    Signal!() restored;
    Signal!() enter;
    Signal!() leave;
    Signal!() focusGained;
    Signal!() focusLost;
    Signal!() close;

    Signal!() defaultAction;

    override bool opCall( const ref SDL_Event ev )
    {
        if( ev.type != SDL_WINDOWEVENT ) return false;
        auto wID = ev.window.windowID;
        int[2] data = [ ev.window.data1, ev.window.data2 ];

        switch(ev.window.event){
            case SDL_WINDOWEVENT_SHOWN: shown(); break;
            case SDL_WINDOWEVENT_HIDDEN: hidden(); break;
            case SDL_WINDOWEVENT_EXPOSED: exposed(); break;
            case SDL_WINDOWEVENT_MOVED: moved(ivec2(data)); break;
            case SDL_WINDOWEVENT_RESIZED: resized(ivec2(data)); break;
            case SDL_WINDOWEVENT_MINIMIZED: minimized(); break;
            case SDL_WINDOWEVENT_MAXIMIZED: maximized(); break;
            case SDL_WINDOWEVENT_RESTORED: restored(); break;
            case SDL_WINDOWEVENT_ENTER: enter(); break;
            case SDL_WINDOWEVENT_LEAVE: leave(); break;
            case SDL_WINDOWEVENT_FOCUS_GAINED: focusGained(); break;
            case SDL_WINDOWEVENT_FOCUS_LOST: focusLost(); break;
            case SDL_WINDOWEVENT_CLOSE: close(); break;
            default: defaultAction();
        }
        return true;
    }
}
+/
