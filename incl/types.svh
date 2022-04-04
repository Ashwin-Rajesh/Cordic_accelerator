`ifndef TYPES_SVH
`define TYPES_SVH

// Representation of fixed point number
class Number #(int p_WIDTH = 32, int p_INT_BITS = 0);
  typedef bit signed[p_WIDTH-1:0] FixedPoint;     // Fixed point representation type
  
  real                realVal;                    // Floating point value representation
  rand FixedPoint     binVal;                     // Fixed point value representation
  
  // Maximum and minimum representable values in fixed point representation
  static FixedPoint maxBinVal = FixedPoint'({1'b0, {p_WIDTH-1{1'b1}}});
  static FixedPoint minBinVal = FixedPoint'({1'b1, {p_WIDTH-1{1'b0}}});
  
  // Maximum and minimum representable values in fixed point representation
  static real maxRealVal = binToReal(maxBinVal);
  static real minRealVal = binToReal(minBinVal);
  
  // Constructor intitalized using real value
  function new(real inp = 0);
    realVal = inp;
    binVal = realToBin(inp);
  endfunction
  
  // Set from a real input value
  function setReal(real inp);
  	realVal = inp;
    binVal = realToBin(inp);
  endfunction
  
  // Set from a binary input value
  function setBin(FixedPoint inp);
	binVal = inp;
    realVal = binToReal(inp);
  endfunction
  
  // Convert real value to binary value
  static function FixedPoint realToBin(real inp);
    return FixedPoint'(inp * (2.0 ** (p_WIDTH - p_INT_BITS - 1)));
  endfunction
  
  // Convert binary value to real value
  static function real binToReal(FixedPoint inp);
    return real'(inp) * (2.0 ** -(p_WIDTH - p_INT_BITS - 1));
  endfunction
  
  // Return string representing the value
  function string toString();
    return $sformatf("0x%8h (%.4f)", binVal, realVal);
  endfunction
  
  // For randomization, adjust real value from randomized binary value
  function void post_randomize();
    realVal = binToReal(binVal);
  endfunction
endclass

// Fixed point representation of angle (q.31 fixed point by default)
class Angle #(int p_WIDTH = 32);
  typedef Number#(p_WIDTH, 0) 	NumType;  // Type to represent the number

  NumType   numVal;           // Angle in numeric -1 to 1 format
  real      radVal;           // Angle in radians (-pi to pi)
  real      degVal;           // Angle in degrees (-180 to 180)
  
  function new(real inpDeg);
    numVal = degToNum(inpDeg);
    degVal = numToDeg(numVal);
    radVal = numToRad(numVal);
  endfunction
  
  // Set from degree value
  function bit setDeg(real inp);
    if(inp < -180 || inp > 180)
      return 0;
    numVal = degToNum(inp);
    degVal = numToDeg(numVal);
    radVal = numToRad(numVal);
    return 1;
  endfunction
  
  // Set from radian value
  function bit setRad(real inp);
    numVal = radToNum(inp);
    degVal = numToDeg(numVal);
    radVal = numToRad(numVal);
  endfunction
  
  // Set from binary value
  function bit setBin(NumType::FixedPoint inp);
    numVal.setBin(inp);
    degVal = numToDeg(numVal);
    radVal = numToRad(numVal);
  endfunction
  
  // Get binary value
  function NumType::FixedPoint getBin();
    return numVal.binVal;
  endfunction

  // Convert number object to radian
  static function real numToRad(NumType inp);
    return inp.realVal * $acos(-1);
  endfunction
  
  // Convert number object to degree
  static function real numToDeg(NumType inp);
    return inp.realVal * 180;
  endfunction
  
  // Convert radian to number object
  static function NumType radToNum(real inp);
    NumType temp = new(inp / $acos(-1));
    return temp;
  endfunction
  
  // Convert degree to number object
  static function NumType degToNum(real inp);
    NumType temp = new(inp / 180);
    return temp;
  endfunction
  
  // Convert fixed point representation to degree
  static function real binToDeg(NumType::FixedPoint inp);
    NumType temp = new();
    temp.setBin(inp);
    return numToDeg(temp);
  endfunction

  // Convert fixed point representation to radian
  static function real binToRad(NumType::FixedPoint inp);
    NumType temp = new();
    temp.setBin(inp);
    return numToRad(temp);
  endfunction
  
  // For randomization, first randomize numeric value
  function void pre_randomize();
    numVal.randomize();
  endfunction

  // After randomizing numeric value, convert it to radian and degree
  function void post_randomize();
    radVal = numToRad(numVal);
    degVal = numToDeg(numVal);
  endfunction
  
  // Convert to string : binary (degree) format
  function string toString();
    return $sformatf("0x%8h (%7.2f deg)", numVal.binVal, degVal);
  endfunction
endclass

`endif
