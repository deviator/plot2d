module plot2d.label;

import std.exception : enforce;
import plot2d.drawable;

interface Label : Drawable
{
    static interface Formatter
    {
        string x(double value, double step);
        string maxXValue() @property;

        string y(double value, double step);
        string maxYValue() @property;
    }
}

class LBGridLabel : Label
{
    Formatter fmt;

    double lineSpacing = 1.5;

    bool onX = true;
    bool onY = true;

    Point space = Point(8, 8);

    this(Formatter fmt)
    {
        this.fmt = enforce(fmt, "formatter is null");
    }

    Point minGridStep(Ctx cr, Style style)
    {
        setupStyle(cr, style);

        Point xte, yte;
        cr.getTextSize(fmt.maxXValue, xte);
        cr.getTextSize(fmt.maxYValue, yte);
        return Point(xte.x * 1.2, yte.y * 2.5);
    }

    override void draw(Ctx cr, Trtor tr, Style style)
    {
        setupStyle(cr, style);

        auto fontsize = style.number.get("fontsize", 15);

        auto im = tr.inMargin;
        auto s = tr.gridStep;
        auto o = tr.gridOffset;
        auto chs = s / tr.scale;
        chs.y *= -1;

        Point te;

        if (onX) for (double i = im.w.min + o.x; i <= im.w.max; i += s.x)
        {
            auto str = fmt.x(tr.toChX(i), chs.x);
            auto pnt = Point(i, im.h.max + space.y);
            foreach (n, ln; str.split("\n"))
            {
                cr.getTextSize(ln, te);
                if (n == 0 && (i - te.x/2 < im.w.min ||
                               i + te.x/2 > im.w.max)) break;
                cr.moveToP(pnt + Point(-te.x/2, te.y));
                cr.showText(ln);
                pnt.y += fontsize * lineSpacing;
            }
        }

        if (onY) for (double i = im.h.max - o.y; i > im.h.min; i -= s.y)
        {
            auto str = fmt.y(tr.toChY(i), chs.y);
            auto pnt = Point(im.w.min - space.x, i);
            foreach (ln; str.split("\n"))
            {
                cr.getTextSize(ln, te);
                cr.moveToP(pnt + Point(-te.x, te.y/2));
                cr.showText(ln);
                pnt.y += fontsize * lineSpacing;
            }
        }
    }

    void setupStyle(Ctx cr, Style style)
    {
        cr.setFont(style.strval.get("fontface", "Monospace"),
                   style.number.get("fontsize", 15));

        cr.setColor(style.color.get("color", Color.mono(0, 1)));
    }
}