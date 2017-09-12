module plot2d.chart.types;

import std.algorithm;
import std.array;
import std.range;

public import plot2d.types : Point;

private alias P = Point;

struct TreStat
{
    double tm, max, val, min;
const pure nothrow @nogc @safe @property:
    P[3] points() { return [maxPnt, valPnt, minPnt]; }
    P maxPnt() { return P(tm, max); }
    P minPnt() { return P(tm, min); }
    P valPnt() { return P(tm, val); }

    bool check()
    {
        return tm == tm &&
              max == max &&
              val == val &&
              min == min;
    }
}

struct BoxStat
{
    double tm, dtm, min, q1, med, q3, max, start, end;

    void set(R)(double tm, double dtm, R rng)
        if (isForwardRange!R && hasLength!R)
    {
        this.tm = tm;
        this.dtm = dtm;
        auto arr = rng.save.array;
        start = arr[0];
        end = arr[$-1];
        auto sarr = arr.sort;
        min = sarr[0];
        q1  = sarr[$/4*1];
        med = sarr[$/4*2];
        q3  = sarr[$/4*3];
        max = sarr[$-1];
    }

    static BoxStat Set(R)(double tm, double dtm, R rng)
        if (isForwardRange!R && hasLength!R)
    {
        BoxStat ret;
        ret.set(tm, dtm, rng);
        return ret;
    }

const @nogc @property pure nothrow:
    P[2] points() { return [minPnt, maxPnt]; }
    P minPnt() { return P(tm, min); }
    P q1Pnt() { return P(tm, q1); }
    P medPnt() { return P(tm, med); }
    P q3Pnt() { return P(tm, q3); }
    P maxPnt() { return P(tm, max); }
}