module plot2d.chart.types;

public import plot2d.types : Point;

struct TreStat
{
    double tm, max, val, min;
    alias P = Point;

const pure nothrow @nogc @safe @property:
    P[3] points() { return [maxPnt, valPnt, minPnt]; }
    P maxPnt() { return P(tm, max); }
    P minPnt() { return P(tm, min); }
    P valPnt() { return P(tm, val); }
}