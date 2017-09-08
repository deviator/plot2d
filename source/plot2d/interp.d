module plot2d.interp;

auto lineInterp(RV, RK)(RV vals, RK keys, float t)
{
    import std.range;

    typeof(keys.front) ak = keys.front, bk = keys.front;
    typeof(vals.front) av = vals.front, bv = vals.front;

    if (t < keys.front) return vals.front;
    
    bool pair = true;

    foreach (k, v; lockstep(keys, vals))
    {
        if (t < k)
        {
            bk = k;
            bv = v;
            pair = true;
            break;
        }
        ak = k;
        av = v;
        pair = false;
    }

    if (!pair) return av;

    auto c = (t - ak) / (bk - ak);
    return av + (bv - av) * c;
}

unittest
{
    import std.math;
    auto v = [1.0f, 4, 5];
    auto k = [0.0f, 1.0f, 2.0f];

    enum eps = float.epsilon;
    assert(fabs(lineInterp(v, k, -1) - v[0]) < eps);
    assert(fabs(lineInterp(v, k,  0) - v[0]) < eps);
    assert(fabs(lineInterp(v, k,  0.5) - 2.5) < eps);
    assert(fabs(lineInterp(v, k,  1) - 4) < eps);
    assert(fabs(lineInterp(v, k,  1.5) - 4.5) < eps);
    assert(fabs(lineInterp(v, k,  2) - 5) < eps);
    assert(fabs(lineInterp(v, k,  3) - 5) < eps);
}

T bezierInterp(size_t N, T)(auto ref const T[N] p, float t)
{
    static if (N > 2)
    {
        T[N-1] tmp;
        foreach (i; 0 .. N-1)
            tmp[i] = p[i] + (p[i+1] - p[i]) * t;
        return bezierInterp(tmp, t);
    }
    else static if (N==2)
        return p[0] + (p[1] - p[0]) * t;
    else static assert(0, "need min 2 values for interpolation");
}