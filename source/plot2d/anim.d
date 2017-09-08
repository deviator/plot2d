module plot2d.anim;

import std.algorithm : min, max;

import plot2d.types;
import plot2d.interp;

interface Transition
{
    /++
        Params:
            dt = time from animation start
            dur = animation duration
        Returns:
            value from 0 to 1
     +/
    float opCall(float dt, float dur)
    out (v)
    {
        assert (v >= 0, "less that zero");
        assert (v <= 1, "more that one");
    };
}

float lineTransition(float dt, float dur)
{ return max(0, min(1, dt / dur)); }

class LineTransition : Transition
{
    override float opCall(float dt, float dur)
    { return lineTransition(dt, dur); }
}

unittest
{
    import std.math;
    auto lt = new LineTransition;
    enum eps = 1e-6;
    void test(float v) { assert(fabs(v) < eps); }
    test(lt(0, 1));
    test(lt(-1, 1));
    test(lt(0.5, 1) - 0.5);
    test(lt(0.5, 2) - 0.25);
    test(lt(2, 1) - 1);
}

class BezierTransition : Transition
{
protected:
    Point zero = Point(0.0f, 0.0f);
    Point one  = Point(1.0f, 1.0f);
    Point p1, p2;

public:
    this() { this(0.5, 0, 0.5, 1); }

    this(float offset) { this(offset, 0, 1-offset, 1); }

    this(float p1x, float p1y, float p2x, float p2y)
    {
        p1 = Point(p1x, p1y);
        p2 = Point(p2x, p2y);
    }

    override float opCall(float dt, float dur)
    { return bezierInterp([zero, p1, p2, one], lineTransition(dt, dur)).y; }
}

class TrueBezierTransition : BezierTransition
{
protected:
    Point[] tbl;

    void buildTable(size_t cnt)
    {
        import std.exception : enforce;
        enforce(cnt >= 2, "bad points count (<2)");
        tbl.length = cnt+1;
        foreach (i; 0 .. cnt+1)
        {
            auto tmp = bezierInterp([zero, p1, p2, one], (i * 1.0f) / cnt);
            if (i > 0) enforce(tmp.x > tbl[i-1].x, "bad transition points");
            tbl[i] = tmp;
        }
    }

public:
    this(size_t cnt=20) { this(0.5, 0, 0.5, 1, cnt); }

    this(float offset, size_t cnt=20) { this(offset, 0, 1-offset, 1, cnt); }

    this(float p1x, float p1y, float p2x, float p2y, size_t cnt=20)
    {
        super(p1x, p1y, p2x, p2y);
        buildTable(cnt);
    }

    override float opCall(float dt, float dur)
    {
        import std.math;
        auto t = lineTransition(dt, dur);

        if (fabs(t) <= float.epsilon) return 0;
        if (fabs(t-1) <= float.epsilon) return 1;

        size_t s = 0, e = tbl.length-1;
        while (e - s > 1)
        {
            auto c = (s+e)/2;
            if (t > tbl[c].x) s = c;
            else if (t < tbl[c].x) e = c;
            else if (t == tbl[c].x) return tbl[c].y;
        }
        return min(1, max(0, (tbl[s] + (tbl[s+1] - tbl[s]) * t).y));
    }
}