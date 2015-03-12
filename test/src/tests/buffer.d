module tests.buffer;

import tests.iface;

class BufferTest : AutoTestWithCases
{
    GLArrayBuffer buf0, buf1;

    void init()
    {
        buf0 = newEMM!GLArrayBuffer;
        buf1 = newEMM!GLArrayBuffer;

        auto origin = [ vec3(1,2,3),
                        vec3(4,5,6),
                        vec3(7,8,9),
                        vec3(10,11,12),
                        vec3(13,14,15)
                      ];

        addSubTest( "set/get data",
        {
            buf0.setData( origin );
            auto test = buf0.getData!vec3;
            return eq( test, origin );
        });

        addSubTest( "set/get sub data",
        {
            buf0.setData( origin );
            buf0.setSubData( 2, [ vec3(12,34,56) ] );
            auto test = buf0.getData!vec3( 1, 2 );
            return eq( test, [ vec3(4,5,6), vec3(12,34,56) ] );
        });

        addSubTest( "map read data",
        {
            buf0.setData( origin );
            auto test = buf0.mapData!vec3( [GLBuffer.MapBits.READ] );
            scope(exit) buf0.unmap();
            return eq( test, origin );
        });

        addSubTest( "map read/write data",
        {
            buf0.setData( origin );
            auto test = buf0.mapData!vec3( [GLBuffer.MapBits.READ,
                                            GLBuffer.MapBits.WRITE] );
            scope(exit) buf0.unmap();

            test[2] = vec3(20,30,40);

            return eq( test, origin[0..2] ~ vec3(20,30,40) ~ origin[3..$] );
        });

        addSubTest( "map read sub data",
        {
            buf0.setData( origin );
            auto test = buf0.mapRangeData!vec3( 3, 2, [GLBuffer.MapBits.READ] );
            scope(exit) buf0.unmap();

            return eq( test, [ vec3(10,11,12), vec3(13,14,15) ] );
        });
    }

    wstring name() @property { return "buffer test"w; }
}
