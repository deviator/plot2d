module plot2d.label;

import std.exception : enforce;
import plot2d.drawable;

interface Label : Drawable, Stylized
{
    static interface Formatter
    {
        string x(double value, double step);
        string maxXValue() @property;

        string y(double value, double step);
        string maxYValue() @property;
    }

    ///
    static auto defaultFmtFunc(double value, double step)
    {
        import std.string;
        auto sf = format("%f", step).tr("0", " ").strip.split(".");
        return format("%.*f", sf[1].length, value);
    }

    ///
    static class DefaultFormatter : Formatter
    {
        string maxX = "0.0", maxY = "0.0";
    override:
        string x(double v, double s)
        {
            auto r = defaultFmtFunc(v, s);
            if (r.length > maxX.length) maxX = r;
            return r;
        }

        string y(double v, double s)
        {
            auto r = defaultFmtFunc(v, s);
            if (r.length > maxY.length) maxY = r;
            return r;
        }

        string maxXValue() @property { return maxX; }
        string maxYValue() @property { return maxY; }
    }
}

class LBGridLabel : Label
{
    mixin StylizedHelper!"label";

    Formatter formatter;

    double lineSpacing = 1.5;

    bool onX = true;
    bool onY = true;

    Point space = Point(8, 8);

    this(Style root, Formatter fmt=null)
    {
        setRootStyle(root);
        formatter = fmt is null ? new DefaultFormatter : fmt;
    }

    Point minGridStep(Ctx cr)
    {
        setupStyle(cr);

        Point xte, yte;
        cr.getTextSize(formatter.maxXValue, xte.x, xte.y);
        cr.getTextSize(formatter.maxYValue, yte.x, xte.y);
        return Point(xte.x * 1.2, yte.y * 2.5);
    }

    override void draw(Ctx cr, Trtor tr)
    {
        setupStyle(cr);

        auto fontsize = style.number.get("fontsize", 15);

        auto im = tr.inMargin;
        auto s = tr.gridStep;
        auto o = tr.gridOffset;
        auto chs = s / tr.scale;
        chs.y *= -1;

        Point te;

        if (onX) for (double i = im.w.min + o.x; i <= im.w.max; i += s.x)
        {
            auto str = formatter.x(tr.toChX(i), chs.x);
            auto pnt = Point(i, im.h.max + space.y);
            foreach (n, ln; str.split("\n"))
            {
                cr.getTextSize(ln, te.x, te.y);
                if (n == 0 && (i - te.x/2 < im.w.min ||
                               i + te.x/2 > im.w.max)) break;
                cr.moveToP(pnt + Point(-te.x/2, te.y));
                cr.showText(ln);
                pnt.y += fontsize * lineSpacing;
            }
        }

        if (onY) for (double i = im.h.max - o.y; i > im.h.min; i -= s.y)
        {
            auto str = formatter.y(tr.toChY(i), chs.y);
            auto pnt = Point(im.w.min - space.x, i);
            foreach (ln; str.split("\n"))
            {
                cr.getTextSize(ln, te.x, te.y);
                cr.moveToP(pnt + Point(-te.x, te.y/2));
                cr.showText(ln);
                pnt.y += fontsize * lineSpacing;
            }
        }
    }

    void setupStyle(Ctx cr)
    {
        cr.setFont(style.strval.get("fontface", "Monospace"),
                   style.number.get("fontsize", 15));

        cr.setColor(style.color.get("color", Color.mono(0, 1)));
    }
}