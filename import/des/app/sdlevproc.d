module des.app.sdlevproc;

public import derelict.sdl2.sdl;

public import des.app.event;

public import des.math.linear.vector;
public import des.util.signal;

import std.string;
import std.range;

import des.util.string;
import des.util.signal;

class AppEventProcException : Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

interface EventProcessor { bool opCall( const ref SDL_Event ); }//Возвращает true, если событие было обработано

class KeyboardEventProcessor : EventProcessor
{
    SignalBox!( const(KeyboardEvent) ) key;

    bool opCall( const ref SDL_Event ev )
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

class MouseEventProcessor : EventProcessor
{
private:
    MouseEvent main_event;
public:
    alias ref const(MouseEvent) in_MouseEvent;
    SignalBox!( in_MouseEvent ) mouse;

    bool opCall( const ref SDL_Event ev )
    {
        switch( ev.type )
        {
            case SDL_MOUSEMOTION:
                auto e = ev.motion;
                main_event.type = MouseEvent.Type.MOTION;
                main_event.pos = ivec2( e.x, e.y );
                main_event.rel = ivec2( e.xrel, e.yrel );
                mouse( main_event );
            return true;
            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP:
                auto e = ev.button;
                if( e.state == SDL_PRESSED )
                {
                    main_event.type = MouseEvent.Type.PRESSED;
                    main_event.btn |= SDL_BUTTON(e.button);
                }
                else
                {
                    main_event.type = MouseEvent.Type.RELEASED;
                    main_event.btn &= SDL_BUTTON(e.button);
                }
                mouse( main_event );
            return true;
            case SDL_MOUSEWHEEL:
                auto e = ev.wheel;
                main_event.type = MouseEvent.Type.WHEEL;
                main_event.whe = ivec2( e.x, e.y );
                mouse( main_event );
            return true;
            default: return false;
        }
    }
}

class WindowEventProcessor : EventProcessor
{
    private enum sig_list =
    [
        "shown",
        "hidden",
        "exposed",
        "moved:ivec2",
        "resized:ivec2",
        "minimized",
        "maximized",
        "restored",
        "enter",
        "leave",
        "focusGained",
        "focusLost",
        "close",
    ];

    SignalBox!() defaultAction;

    mixin( getSignalsString( sig_list ) );

    bool opCall( const ref SDL_Event ev )
    {
        if( ev.type != SDL_WINDOWEVENT ) return false;
        auto wID = ev.window.windowID;
        int[2] data = [ ev.window.data1, ev.window.data2 ];

        mixin( getSignalsCallString( "ev.window.event", ["data"],
                                      sig_list, "defaultAction();" ) );
        return true;
    }

private:
static:

    string getSignalsString( in string[] list )
    {
        string[] ret;
        foreach( elem; list )
            ret ~= format( "SignalBox!(%s) %s;",
                    getArgs(elem), getName(elem) );
        return ret.join("\n");
    }

    string getSignalsCallString( string vname, in string[] param_ctor_data,
                                 in string[] list, string default_action )
    {
        string[] ret;

        ret ~= format( `switch(%s){`, vname );

        foreach( elem; list )
        {
            auto name = getName( elem );
            auto params = getParams( elem, param_ctor_data );
            auto event_name = getEventName( name );
            ret ~= format( `case %s: %s(%s); break;`,
                            event_name, name, params );
        }

        ret ~= format( `default: %s`, default_action );

        ret ~= `}`;

        return ret.join("\n");
    }

    string getName( string list_elem ) { return list_elem.split(":")[0]; }

    string getArgs( string list_elem )
    {
        auto sp = list_elem.split(":");
        if( sp.length < 2 ) return "";
        return sp[1];
    }

    string getParams( string list_elem, in string[] param_ctor_data )
    {
        auto args = getArgs( list_elem ).split(",");
        if( args.length > param_ctor_data.length )
            assert( 0, format( "dab params length %s:%d", __FILE__, __LINE__-2 ) );

        string[] ret;
        foreach( arg, pcd; zip( args, param_ctor_data ) )
            ret ~= format( "%s(%s)", arg, pcd );
        return ret.join(",");
    }

    /+
        чтобы в compile time работала функция toUpper
        нужно поправить в std.uni функцию toCase,
        там к массиву result прибавляется элемент,
        который имеет тип dchar, хотя сам массив 
        result имеет тип входящей строки, следовательно,
        зачастую, это string, и элементы char.
        нужно принудительно конвертировать переменную 'c',
        добавляемую к массиву result к типу элементов этого массива.

        пример:
            result ~= cast(typeof(result).init[0])c;
    +/
    string getEventName( string signame )
    { return "SDL_WINDOWEVENT_" ~ signame.toSnakeCase.toUpper; }
}
