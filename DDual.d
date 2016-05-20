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
	else { 
	    static assert(0,"Operator '"~op~"' not implemented");
	}
    }
    
    Dual!(T) opBinary(string op, L)(L rhs) if(isNumeric!(L) && isAssignable!(T,L)) {
	return this.opBinary!(op)(make_dual(rhs));
    }

    Dual!(T) opBinaryRight(string op, L)(L lhs) if(isNumeric!(L) && isAssignable!(T,L)) {
	return make_dual(to!(T)(lhs)).opBinary!(op)(this);
    }
}//end struct


Dual!(T) make_dual(T,L)(T a, L b=0) if(isAssignable!(T,L)){
    return Dual!(T)(a,to!(T)(b));
}
//Dual!(L) make_dual(T,L)(T a, L b=0) if(!isAssignable!(T,L)){
//    return Dual!(L)(to!(L)(a),b);
//}



unittest {
    
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
    assert(h == make_dual(3.0));
}
