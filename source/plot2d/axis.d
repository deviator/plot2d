module plot2d.axis;

import plot2d.drawable;

class Axis : Drawable
{
    bool vertical = true;
    bool horisontal = true;

    double[] dash = [];
    double dashOffset = 0.0;

    override void draw(Ctx cr, Trtor tr, Style st)
    {
        setupStyle(cr, st);
        drawLines(cr, tr, st);
        cr.stroke();
    }

    void setupStyle(Ctx cr, Style style)
    {
        cr.setLineWidth(style.number.get("linewidth", 1));
        cr.setColor(style.color.get("color", Color.mono(0, 0.8)));
        cr.setDash(dash, dashOffset);
    }

    abstract void drawLines(Ctx, Trtor, Style);
}

class LBAxis : Axis
{
    override void drawLines(Ctx cr, Trtor tr, Style style)
    {
        auto im = tr.inMargin;

        if (vertical) cr.lineP2P(im.lt, im.lb);
        if (horisontal) cr.lineP2P(im.lb, im.rb);
    }
}

class ZeroAxis : Axis
{
    override void drawLines(Ctx cr, Trtor tr, Style style)
    {
        auto im = tr.inMargin;
        auto z = tr.toDA(0,0);
        if (vertical) cr.lineP2P(z.x, im.h.min, z.x, im.h.max);
        if (horisontal) cr.lineP2P(im.w.min, z.y, im.w.max, z.y);
    }
}

class Grid : Axis
{
    override void drawLines(Ctx cr, Trtor tr, Style style)
    {
        auto im = tr.inMargin;
        auto s = tr.gridStep;
        auto o = tr.gridOffset;

        if (vertical)
            for (double i = im.w.min + o.x; i <= im.w.max; i += s.x)
                cr.lineP2P(i, im.h.max, i, im.h.min);

        if (horisontal)
            for (double i = im.h.max - o.y; i > im.h.min; i -= s.y)
                cr.lineP2P(im.w.min, i, im.w.max, i);
    }
}