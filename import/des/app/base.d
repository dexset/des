module des.app.base;

///
class AppException : Exception
{
    this( string msg, string file = __FILE__, size_t line = __LINE__ ) @safe pure nothrow
    { super( msg, file, line ); }
}

///
interface App
{
protected:
    /// sleep after step
    void delay();

public:
    /// processing
    bool step();

    ///
    @property bool isRuning();

    /// main loop
    final void run() { while( isRuning && step() ) delay(); }

    ///
    void quit();
}
