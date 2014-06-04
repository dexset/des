module desutil.socket;

public import std.socket;
import std.socketstream;

import desutil.pdata;

class SocketException: Exception
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, int line=__LINE__ ) 
    { super( msg, file, line ); } 
}

class SListener
{
private:
    Socket server;
    Socket client;
    void delegate( immutable ubyte[] ) cb;

    void checkClient()
    {
        if( client is null )
        {
            server.blocking(true);
            client = server.accept();
            server.blocking(false);
        }
    }

    immutable (ubyte)[] receiveAll( Socket cli )
    {
        int bs = -1;
        int count = -1;
        int fin_count = -1;

        ubyte[] raw_data;

        while( count != 0 )
        {
            ubyte[] buffer;

            buffer.length = bs == -1 ? size_t.sizeof : bs;

            auto received = client.receive( buffer );
            if( received == 0 )
            {
                client = null;
                return [];
            }

            if( count == -1 )
            {
                ubyte[] tbuffer;
                tbuffer ~= buffer;
                auto ssz = buffer.length % size_t.sizeof;
                if( ssz != 0 )
                    tbuffer.length += size_t.sizeof - ssz;
                auto val = (cast(size_t[])(tbuffer))[0];
                if( bs == -1 )
                {
                    bs = cast(int)val;
                }
                else if( fin_count == -1 )
                {
                    fin_count = cast(int)(val);
                    count = fin_count + bs - fin_count % bs;
                }
                continue;
            }

            raw_data ~= buffer;
            count -= bs;
        }
        return raw_data[ 0 .. fin_count ].idup;
    }
public:
    this( Address addr )
    {
        server = new TcpSocket();
        server.setOption( SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true );
        server.bind( addr );
        server.listen(10);
        client = null;
    }

    this( ushort port ){ this( new InternetAddress( port ) ); }

    void setReceiveCB( void delegate( immutable ubyte[] ) _cb ){ cb = _cb; }

    void step()
    {
        checkClient();

        if( client is null )
            return;

        cb(receiveAll( client ));
    }
}

class SSender
{
private:
    Socket sender;
    SocketStream sstream;
    size_t bs = 16;
public:
    this( Address addr )
    {
        sender = new TcpSocket();
        sender.connect( addr );
        sstream = new SocketStream( sender );
    }

    this( ushort port ) { this( new InternetAddress(port) ); }

    void send( in ubyte[] data )
    {
        sstream.writeBlock( cast(void*)&bs, size_t.sizeof ); 
        auto length = data.length;
        sstream.writeBlock( cast(void*)&length, bs ); 

        auto raw_data = data.dup;
        length += bs - raw_data.length % bs;
        raw_data.length = length;
        
        auto ptr = raw_data.ptr;
        for( int i = 0; i < length; i+=bs )
        {
            sstream.writeBlock( cast(void*)ptr, bs );
            ptr += bs;
        }
    }
}

unittest
{
    import std.random;
    SListener ll = new SListener( 4040 );
    SSender ss = new SSender( 4040 );
    ubyte[100] data;
    foreach( ref d; data )
        d = cast(ubyte)uniform( 100, 255 );
    ubyte[100] rdata;

    auto cb = ( immutable ubyte[] data )
    {
        rdata = data.dup;
    };
    ll.setReceiveCB( cb );
    ss.send( data );
    ll.step();
    assert( data == rdata );
}
