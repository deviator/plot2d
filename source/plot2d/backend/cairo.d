///
module plot2d.backend.cairo;

import plot2d.backend.base;

version (cairo):

import cairo.Context;

///
class CairoCtx : Ctx
{
    /// set this before draw
    Context cr;

override:
    void save() { cr.save(); }
    void restore() { cr.restore(); }
    void stroke() { cr.stroke(); }
    void fill() { cr.fill(); }
    void moveTo(double x, double y) { cr.moveTo(x, y); }
    void lineTo(double x, double y) { cr.lineTo(x, y); }
    void setLineWidth(double lw) { cr.setLineWidth(lw); }
    void showText(string str) { cr.showText(str); }
    void setDash(double[] dash, double offset) { cr.setDash(dash, offset); }
    void setColor(double r, double g, double b, double a=1)
    { cr.setSourceRgba(r, g, b, a); }

    void getTextSize(string str, out double w, out double h)
    {
        cairo_text_extents_t te;
        cr.textExtents(str, &te);
        w = te.width;
        h = te.height;
    }

    void setFont(string name, double size)
    {
        cr.selectFontFace(name,
            cairo_font_slant_t.NORMAL,
            cairo_font_weight_t.NORMAL);
        cr.setFontSize(size);
    }

    void clipViewport(Viewport vp)
    {
        cr.moveTo(vp.w.min, vp.h.min);
        cr.lineTo(vp.w.max, vp.h.min);
        cr.lineTo(vp.w.max, vp.h.max);
        cr.lineTo(vp.w.min, vp.h.max);
        cr.lineTo(vp.w.min, vp.h.min);
        cr.clip();
        cr.newPath();
    }
}