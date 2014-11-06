module des.app.base;

class AppException : Exception
{
    @safe pure nothrow this( string msg, string file = __FILE__, size_t line = __LINE__ )
    { super( msg, file, line ); }
}

interface App
{
protected:
    void delay();

public:
    bool step();

    @property bool isRuning();

    final void run() { while( isRuning && step() ) delay(); }

    void quit();
}
