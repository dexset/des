module tests;

public import tests.iface;

import tests.buffer;
import tests.bufferPRWCM;
import tests.multidrawelementsindirect;
import tests.ssbo_light;
import tests.simpletexture;

Test[] getAllTests()
{
    Test[] ret;

    //ret ~= new BufferTest;
    //ret ~= new BufferPRWCM;
    //ret ~= new MultiDrawElementsIndirectTest;
    //ret ~= new SSBOLightTest;
    ret ~= new SimpleTextureTest;

    return ret;
}
