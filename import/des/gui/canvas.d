module des.gui.canvas;

import des.gui.base;

interface DiCanvas
{
    void preDraw();
    DiRect pushDrawRect( DiRect );
    void popDrawRect();
    void postDraw();
}
