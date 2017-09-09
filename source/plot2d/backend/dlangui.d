///
module plot2d.backend.dlangui;

import plot2d.backend.base;

version (dlangui):

import dlangui;

alias PPoint = plot2d.Point;
alias PColor = plot2d.Color;

alias UIPoint = dlangui.PointF;
alias UIColor = dlangui.Color;

import std.array;
import std.typecons : Tuple;

///
class DlangUICtx : Ctx
{
protected:
    alias Line = Tuple!(PPoint, PPoint);
    PPoint current;
    Appender!(Line[]) lineBuffer;
    float lineWidth = 1.0;
    PColor color;

public:

    DrawBuf buf;

override:
    void save()
    {
        // TODO
    }

    void restore()
    {
        // TODO
    }

    void stroke()
    {
        foreach (ln; lineBuffer.data)
            buf.drawLineF(UIPoint(ln[0].x, ln[1].y),
                          UIPoint(ln[1].x, ln[1].y),
                          lineWidth, UIColor.dark_red);
        lineBuffer.clear();
    }

    void fill()
    {
    }

    void moveTo(double x, double y) { current = PPoint(x,y); }

    void lineTo(double x, double y)
    {
        lineBuffer.put(Line(current, PPoint(x,y)));
        moveTo(x, y);
    }

    void setLineWidth(double lw) { lineWidth = lw; }

    void showText(string str)
    {
        
    }

    void setDash(double[] dash, double offset)
    {
        
    }

    void setColor(double r, double g, double b, double a=1)
    { color = PColor(r,g,b,a); }

    void getTextSize(string str, out double w, out double h)
    {
        // TODO
    }

    void setFont(string name, double size)
    {
        // TODO
    }

    void clipViewport(Viewport vp)
    {
        // TODO
    }
}