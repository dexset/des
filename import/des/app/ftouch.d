module des.app.ftouch;

import derelict.sdl2.sdl;

import des.util.arch;
import des.app.evproc;

/// finger touch event
struct FTouchEvent
{
    ///
    enum Type
    {
        MOTION = SDL_FINGERMOTION, /// SDL_FINGERMOTION,
        DOWN   = SDL_FINGERDOWN,   /// SDL_FINGERDOWN,
        UP     = SDL_FINGERUP      /// SDL_FINGERUP
    }

    ///
    Type type;

    /// touch device index
    size_t touch_id;

    /// finger index
    size_t finger_id;

    /// position [(0,0)..(1,1)]
    vec2 pos;

    /// moved distance [(0,0)..(1,1)]
    vec2 rel;

    ///
    float pressure;
}

///
alias in_FTouchEvent = ref const(FTouchEvent);

/// finger touch event processor
class FTouchEventProcessor : BaseSDLEventProcessor
{
    ///
    Signal!( in_FTouchEvent ) signal;

    ///
    alias signal this;

    bool procSDLEvent( in SDL_Event ev )
    {
        switch( ev.type )
        {
            case SDL_FINGERMOTION:
            case SDL_FINGERDOWN:
            case SDL_FINGERUP:
                with( ev.tfinger )
                    signal( FTouchEvent(
                                cast(FTouchEvent.Type)ev.type,
                                touchId,
                                fingerId,
                                vec2(x,y),
                                vec2(dx,dy),
                                pressure )
                          );
                return true;
            default: return false;
        }
    }
}
