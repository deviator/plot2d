///
module plot2d.backend.base;

public import plot2d.types;

///
interface Ctx
{
    ///
    void save();
    ///
    void restore();
    ///
    void stroke();
    ///
    void fill();
    ///
    void moveTo(double x, double y);
    ///
    void lineTo(double x, double y);
    ///
    void setLineWidth(double lw);
    ///
    void showText(string str);
    ///
    void setDash(double[] dash, double offset);
    ///
    void setColor(double r, double g, double b, double a=1);
    ///
    void getTextSize(string str, out double w, out double h);
    ///
    void setFont(string name, double size);
    ///
    void clipViewport(Viewport vp);

final:
    ///
    void moveToP(P)(P p) { moveTo(p.x, p.y); }
    ///
    void lineToP(P)(P p) { lineTo(p.x, p.y); }
    ///
    void lineP2P()(auto ref const Point p0, Point[] ps...)
    {
        moveToP(p0);
        foreach (p; ps) lineToP(p);
    }
    ///
    void lineP2P()(double x1, double y1, double x2, double y2)
    { lineP2P(Point(x1, y1), Point(x2, y2)); }
    ///
    void setColor(C)(C c) { setColor(c.r, c.g, c.b, c.a); }
    ///
    void setColor(C)(C c, double a) { setColor(c.r, c.g, c.b, a); }
}

/++ mixin string for saving Context
    and restore on exit from scope
+/
string scopeSave(alias cr)()
    if (is(typeof(cr) == Ctx))
{
    import std.string : format;
    return format(q{
        %1$s.save();
        scope(exit)
            %1$s.restore();
    }, __traits(identifier, cr));
}