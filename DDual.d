/*
 * Dual Number automatic differentiation implementation
 * for the D programming language.
 *
 *
 */



import std.math;
import std.traits;
import std.conv;

struct Dual(T) {
    T first;
    T second;
    
    this(T f, T s=0) {
	first = f;
	second = s;
    }

    Dual!(T) opUnary(string op)() {
        
        static if(op == "-") {
            return Dual!(T)(-first, -second);
        }
        else {
            static assert(0, "Operator '"~op~"' not implemented");
        }
    }
    
    
    Dual!(T) opBinary(string op, L)(Dual!(L) rhs) if(isAssignable!(T,L)) {

	static if(op == "+") {
	    return Dual!(T)(first + rhs.first, 
			    second + rhs.second);
	}
	else static if (op == "-") {
	    return Dual!(T)(first - rhs.first, 
			    second - rhs.second);
	}
	else static if (op == "*") {
	    return Dual!(T)(first*rhs.first, 
			    second*rhs.first + first*rhs.second);
	}
        else static if (op == "/") {
            return Dual!(T)(first/rhs.first,
                            (second*rhs.first - first*rhs.second)/(rhs.first*rhs.first));
        }
	else { 
	    static assert(0,"Operator '"~op~"' not implemented");
	}
    }
    
    Dual!(T) opBinary(string op, L)(L rhs) if(isNumeric!(L) && isAssignable!(T,L)) {
	return this.opBinary!(op,T)(make_dual(to!(T)(rhs),to!(T)(0)));
    }

    Dual!(T) opBinaryRight(string op, L)(L lhs) if(isNumeric!(L) && isAssignable!(T,L)) {
	return make_dual(to!(T)(lhs),to!(T)(0)).opBinary!(op,T)(this);
    }
}//end struct



//------------------------------------------------------------
// Utility function to make Dual!T instances
//------------------------------------------------------------
Dual!(T) make_dual(T,L)(T a, L b=0) {
    static assert(isAssignable!(T,L));
    return Dual!(T)(a,to!(T)(b));
}


//------------------------------------------------------------
// Overloads for analytical derivatives of std.math functions
//------------------------------------------------------------

//-------- "Classics" ----------------------
pure nothrow @nogc @safe 
Dual!(T) abs(T)(Dual!(T) x) {
    return Dual!(T)(std.math.abs(x.first), x.second*std.math.sgn(x.first));
}

pure nothrow @nogc @safe 
Dual!(T) sqrt(T)(Dual!(T) x) {
    T sqrtx = std.math.sqrt(x.first);
    return Dual!(T)(sqrtx, T(1)/(T(2)*sqrtx));
}


//-------- "Trig functions" ----------------
pure nothrow @nogc @safe 
Dual!(T) sin(T)(Dual!(T) x) {
    return Dual!(T)(std.math.sin(x.first), x.second*std.math.cos(x.first));
}

pure nothrow @nogc @safe 
Dual!(T) cos(T)(Dual!(T) x) {
    return Dual!(T)(std.math.cos(x.first), -x.second*std.math.sin(x.first));
}

pure nothrow @nogc @safe 
Dual!(T) tan(T)(Dual!(T) x) {
    auto cx = std.math.cos(x.first);
    return Dual!(T)(std.math.tan(x.first), x.second/(cx*cx));
}

pure nothrow @nogc @safe 
Dual!(T) exp(T)(Dual!(T) x) {
    T ex = std.math.exp(x.first);
    return Dual!(T)(ex, x.second*ex);
}

pure nothrow @nogc @safe 
Dual!(T) sinh(T)(Dual!(T) x) {
    return Dual!(T)(std.math.sinh(x.first), 
                    x.second*std.math.cosh(x.first));
}

pure nothrow @nogc @safe 
Dual!(T) cosh(T)(Dual!(T) x) {
    return Dual!(T)(std.math.cosh(x.first), 
                    x.second*std.math.sinh(x.first));
}

pure nothrow @nogc @safe
Dual!(T) pow(T,L)(Dual!(T) x, L y) {
    static assert(isAssignable!(T,L));
    return Dual!(T)(std.math.pow(x.first,y), x.second*y*std.math.pow(x.first,y-1));
}





//------------------------------------------------------------
//------------------------------------------------------------
//------------------------------------------------------------
unittest {
    import std.stdio;

    //------------------------------------------------------------
    // Test basic arithmetic operations
    //------------------------------------------------------------
    auto a = make_dual(1.0,2.0);
    auto b = make_dual(1.0,2.0);
    assert(a == b);

    auto c = make_dual(2.0, 4.0);
    auto d = a+b;
    assert(c == d);

    auto e = a*2.0;
    assert(c == e);

    auto f = a*2;
    assert(c == f);

    auto g = 2*a;
    assert(c == g);
    
    auto h = a+2;
    assert(h == make_dual(3.0,2.0));

    auto i = g/2;
    assert(i == a);

    auto j = -a;
    assert(j == -1*a);

    //------------------------------------------------------------
    // Test derivatives of easy functions
    //------------------------------------------------------------
    auto x = make_dual(2.0, 1.0);
    double xp = (x*x).second; //test df/dx = 2x for f(x) = x*x
    assert(xp == 2*x.first);

    xp = (1/x).second;
    assert(xp == -1/(x.first*x.first)); // test df/dx = -1/(x^2) for f(x) = 1/x


    //------------------------------------------------------------
    // Test derivatives of library function overloads
    //------------------------------------------------------------
    auto absx = abs(-x);
    assert( std.math.abs(absx.first - std.math.abs(-1*x.first)) < 1.0e-14 );
    assert( std.math.abs(absx.second - (-1*x.second)*std.math.sgn(-1*x.first)) < 1.0e-14 );

    auto sqrtx = sqrt(x);
    assert( std.math.abs(sqrtx.first - std.math.sqrt(x.first))<1.0e-14 );
    assert( std.math.abs(sqrtx.second - 1.0/(2*std.math.sqrt(x.first)))<1.0e-14 );

    auto cx = cos(x);
    assert(std.math.abs(cx.first -std.math.cos(x.first)) < 1.0e-14);
    assert(std.math.abs(cx.second - -x.second*std.math.sin(x.first))<1.0e-14);

    auto sx = sin(x);
    assert(std.math.abs(sx.first - std.math.sin(x.first)) < 1.0e-14);
    assert(std.math.abs(sx.second - x.second*std.math.cos(x.first))<1.0e-14);

    auto tx = tan(x);
    assert( std.math.abs(tx.first - std.math.tan(x.first))<1.0e-14 );
    assert( std.math.abs(tx.second - 1.0/(std.math.cos(x.first)*std.math.cos(x.first)))<1.0e-14 );

    auto ex = exp(x);
    assert(std.math.abs(ex.first - std.math.exp(x.first))<1.0e-14);
    assert(std.math.abs(ex.second - x.second*std.math.exp(x.first))<1.0e-14);

    double y = 2.5;
    auto pxy = pow(x,y);
    assert( std.math.abs(pxy.first - std.math.pow(x.first,y)) < 1.0e-14 );
    assert( std.math.abs(pxy.second - y*std.math.pow(x.first,y-1)) < 1.0e-14 );

    //------------------------------------------------------------
    writeln("All tests completed successfully");
}
version(unittest) {
    void main() {}
}