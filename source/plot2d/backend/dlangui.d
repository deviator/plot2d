///
module plot2d.backend.dlangui;

import plot2d.backend.base;

version (dlangui):

import dlangui;

///
class DlangUICtx : Ctx
{
override:
    void save();
    void restore();
    void stroke();
    void fill();
    void moveTo(double x, double y);
    void lineTo(double x, double y);
    void setLineWidth(double lw);
    void showText(string str);
    void setDash(double[] dash, double offset);
    void setColor(double r, double g, double b, double a=1);
    void getTextSize(string str, out double w, out double h);
    void setFont(string name, double size);
    void clipViewport(Viewport vp);
}