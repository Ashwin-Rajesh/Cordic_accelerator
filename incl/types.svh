`ifndef TYPES_SVH
`define TYPES_SVH

// Representation of fixed point number
class number #(int width = 32, int int_bits = 0);
  real 							val;
  
  typedef bit signed[width-1:0] fixed_pt;
  
  rand fixed_pt 				val_bin;
  
  static fixed_pt max_val_bin = fixed_pt'({1'b0, {width-1{1'b1}}});
  static fixed_pt min_val_bin = fixed_pt'({1'b1, {width-1{1'b0}}});
  
  static real max_val_real = bin_to_real(max_val_bin);
  static real min_val_real = bin_to_real(min_val_bin);
  
  function new(real inp = 0);
    val = inp;
    val_bin = real_to_bin(inp);
  endfunction
  
  function set_real(real inp);
  	val = inp;
    val_bin = real_to_bin(inp);
  endfunction
  
  function set_bin(fixed_pt inp);
	val_bin = inp;
    val = bin_to_real(inp);
  endfunction
  
  static function fixed_pt real_to_bin(real inp);
    return fixed_pt'(inp * (2.0 ** (width - int_bits - 1)));
  endfunction
  
  static function real bin_to_real(fixed_pt inp);
    return real'(inp) * (2.0 ** -(width - int_bits - 1));
  endfunction
  
  function string to_string();
    return $sformatf("0x%8h (%.4f)", val_bin, val);
  endfunction
  
  function void post_randomize();
    val = bin_to_real(val_bin);
  endfunction
endclass

// Fixed point representation of angle (q.31 fixed point by default)
class angle #(int width = 32);
  typedef number#(width, 0) 	num_type;

  num_type				 		val_num;
  
  real val_rad;
  
  real val_deg;
  
  function new(real inp_deg);
    val_num = deg_to_num(inp_deg);
    val_deg = num_to_deg(val_num);
    val_rad = num_to_rad(val_num);
  endfunction
  
  function void set_deg(real inp);
    val_num = deg_to_num(inp);
    val_deg = num_to_deg(val_num);
    val_rad = num_to_rad(val_num);
  endfunction
  
  function void set_rad(real inp);
    val_num = rad_to_num(inp);
    val_deg = num_to_deg(val_num);
    val_rad = num_to_rad(val_num);
  endfunction
  
  function void set_bin(num_type::fixed_pt inp);
    val_num.set_bin(inp);
    val_deg = num_to_deg(val_num);
    val_rad = num_to_rad(val_num);
  endfunction

  static function real num_to_rad(num_type inp);
    return inp.val * $acos(-1);
  endfunction
  
  static function real num_to_deg(num_type inp);
    return inp.val * 180;
  endfunction
  
  static function num_type rad_to_num(real inp);
    num_type temp = new(inp / $acos(-1));
    return temp;
  endfunction
  
  static function num_type deg_to_num(real inp);
    num_type temp = new(inp / 180);
    return temp;
  endfunction
  
  static function real bin_to_deg(num_type::fixed_pt inp);
    num_type temp = new();
    temp.set_bin(inp);
    return num_to_deg(temp);
  endfunction

  static function real bin_to_rad(num_type::fixed_pt inp);
    num_type temp = new();
    temp.set_bin(inp);
    return num_to_rad(temp);
  endfunction
  
  function void pre_randomize();
    val_num.randomize();
  endfunction
  
  function void post_randomize();
    val_rad = num_to_rad(val_num);
    val_deg = num_to_deg(val_num);
  endfunction
  
  function string to_string();
    return $sformatf("0x%8h (%7.2f deg)", val_num.val_bin, val_deg);
  endfunction
  
  function string to_string_long();
    return $sformatf("0x%8h %7.4f (%7.2f deg, %7.4f rad)", val_num.val_bin, val_num.val, val_deg, val_rad);
  endfunction
endclass

`endif
