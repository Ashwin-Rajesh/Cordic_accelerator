`ifndef TYPES_TEST_SV
`define TYPES_TEST_SV

`include "types.svh"

program testbench;
  localparam width = 32;
  localparam int_bits = 3;

  typedef number #(width, int_bits) num_type;
  typedef angle #(width) angle_type;
  
  num_type 		num_obj      = new(0);
  angle_type 	angle_obj    = new(0);
  
  initial begin
    $display("Running number test for format q%2d\.%2d", int_bits, width - int_bits - 1);
    $display("Max value : 0x%8h (%f)", num_obj.max_val_bin, num_obj.max_val_real);
    $display("Min value : 0x%8h (%f)", num_obj.min_val_bin, num_obj.min_val_real);
    
    $display(num_obj.to_string());
    repeat(10) begin
      num_obj.randomize();
      $display(num_obj.to_string());
      assert(num_obj.val >= num_obj.min_val_real 		&& num_obj.val <= num_obj.max_val_real);
      assert(num_obj.val == num_obj.bin_to_real(num_obj.val_bin));
      assert(num_obj.val_bin == num_obj.real_to_bin(num_obj.val));
      assert(num_obj.val_bin >= num_obj.min_val_bin 	&& num_obj.val_bin <= num_obj.max_val_bin);
    end
	
    $display("Running angle test for format q0.%2d", width - 1);
    
    $display(angle_obj.to_string());
    repeat(10) begin
      angle_obj.randomize();
      $display(angle_obj.to_string());
    end
  end
endprogram

`endif
