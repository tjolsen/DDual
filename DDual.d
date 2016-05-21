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
Dual!(T) make_dual(T)(T a, T b=0) {
    return Dual!(T)(a,b);
}


//------------------------------------------------------------
// Overloads for analytical derivatives of transcendental functions
//------------------------------------------------------------

Dual!(T) sin(T)(Dual!(T) x) {
    return Dual!(T)(std.math.sin(x.first), x.second*std.math.cos(x.first));
}

Dual!(T) cos(T)(Dual!(T) x) {
    return Dual!(T)(std.math.cos(x.first), -x.second*std.math.sin(x.first));
}

Dual!(T) exp(T)(Dual!(T) x) {
    T ex = std.math.exp(x.first);
    return Dual!(T)(ex, x.second*ex);
}



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

    //------------------------------------------------------------
    // Test derivatives of easy functions
    //------------------------------------------------------------
    auto x = make_dual(2.0, 1.0);
    double xp = (x*x).second; //test df/dx = 2x for f(x) = x*x
    assert(xp == 2*x.first);

    xp = (1/x).second;
    assert(xp == -1/(x.first*x.first)); // test df/dx = -1/(x^2) for f(x) = 1/x


    //------------------------------------------------------------
    // Test derivatives of transcendental functions
    //------------------------------------------------------------
    auto cx = cos(x);
    assert(abs(cx.first -std.math.cos(x.first)) < 1.0e-10);
    assert(abs(cx.second - -x.second*std.math.sin(x.first))<1.0e-10);

    auto sx = sin(x);
    assert(abs(sx.first - std.math.sin(x.first)) < 1.0e-10);
    assert(abs(sx.second - x.second*std.math.cos(x.first))<1.0e-10);

    auto ex = exp(x);
    assert(abs(ex.first - std.math.exp(x.first))<1.0e-10);
    assert((ex.second - x.second*std.math.exp(x.first))<1.0e-10);


    //------------------------------------------------------------
    writeln("All tests completed successfully");
}
version(unittest) {
    void main() {}
}