module des.gui.layout;

import des.gui.base;
import des.gui.shape;

interface DiLayoutItem
{
    @property
    {
        ///
        DiShape shape();
        ///
        const(DiShape) shape() const;
    }

    void relayout();
}

///
interface DiLayout
{
    ///
    void opCall( in DiShape container,
                 DiLayoutItem[] inner );
}
