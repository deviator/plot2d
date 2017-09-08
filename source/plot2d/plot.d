///
module plot2d.plot;

import std.datetime : StopWatch;

import std.stdio;

import plot2d.drawable;
import plot2d.axis;
import plot2d.label;
import plot2d.style;
import plot2d.trtor;
import plot2d.chart;
import plot2d.util;

///
class Plot
{
public:
    ///
    struct Settings
    {
        ///
        Viewport viewport = {w: DimSeg(0, 1), h: DimSeg(0, 1)};

        /// use summury charts viewports
        bool autoFit = true;

        ///
        Point minGridStep = Point(20,20);

        /// from border to axis
        Border margin = Border(60, 10, 40, 40);

        /// from axis to charts
        Border padding = Border(0, 10);
    }

    ///
    Settings settings;

    ///
    Trtor tr;
    /// namespaced style
    NSStyle style;

    ///
    Axis axis;
    ///
    Grid grid;
    ///
    LBGridLabel label;

    ///
    Chart[] charts;

    ///
    this()
    {
        tr = new Trtor;
        style = new NSStyle;

        axis = new LBAxis(style);
        grid = new Grid(style);
        grid.dash = [5, 8];
        label = new LBGridLabel(style);
    }

    ///
    T add(T)(T ch) if (is(T : Chart))
    {
        charts ~= ch;
        if (auto sch = cast(Stylized)ch)
            sch.setRootStyle(style);
        return ch;
    }

    ///
    void updateCharts()
    {
        foreach (c; charts)
            c.update();
    }

    ///
    void draw(Ctx cr, Point size)
    {
        if (recalculateTrtor(cr, size)) return;
        drawElements(cr);
    }

protected:

    int recalculateTrtor(Ctx cr, Point sz)
    {
        auto vp = getViewport();

        tr.setSMPV(sz, settings.margin, settings.padding, vp);

        Point lmgs;
        {
            mixin(scopeSave!cr);
            lmgs = label.minGridStep(cr);
        }

        tr.optimizeGridStep(
            Point(max(settings.minGridStep.x, lmgs.x * 1.25),
                  max(settings.minGridStep.y, lmgs.y * 1.25)));

        // invert '<=' to '>' for nan-check
        if (tr.gridStep.x > 0 && tr.gridStep.y > 0) { }
        else
        {
            .warning("bad grid step: ", tr.gridStep);
            return 1;
        }

        tr.correctGridOffset();
        return 0;
    }

    Viewport getViewport()
    {
        Viewport ret = settings.viewport;

        if (charts.length == 0 ||
            !settings.autoFit) return ret;

        bool s = false; // for setup first viewport
        foreach (c; charts.filter!"a.visible")
        {
            if (s) ret.expand(c.viewport);
            else { ret = c.viewport; s = true; }
        }

        double minViewDiff = double.epsilon * 1e3;

        if (abs(ret.w.diff) < minViewDiff)
            ret.w.stepExpand(minViewDiff);

        if (abs(ret.h.diff) < minViewDiff)
            ret.h.stepExpand(minViewDiff);

        return ret;
    }

    void drawElements(Ctx cr)
    {
        foreach (p; chain(only(cast(Drawable)axis,
                               cast(Drawable)grid,
                               cast(Drawable)label),
                    charts.map!(a=>cast(Drawable)a)))
        {
            if (p is null) continue;
            mixin(scopeSave!cr);
            if (auto c = cast(Chart)p)
                if (!c.visible) continue;
            p.draw(cr, tr);
        }
    }
}