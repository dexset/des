module des.gui.context;

import des.gui.widget;
import des.gui.canvas;

interface DiContext
{
    ///
    DiCanvas createTop( DiWidget );
    ///
    void removeTop( DiWidget );

    /+ TODO

    DiCanvas createCanvas()

    Frame Buffer Object for cached drawing

    +/

    ///
    void quit();

    ///
    void startTextInput();
    ///
    void stopTextInput();
}

///
class DiContextException : Exception
{
    ///
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure nothrow @safe
    { super( msg, file, line ); }
}
