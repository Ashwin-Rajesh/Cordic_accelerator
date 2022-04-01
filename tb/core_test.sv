`ifndef CORE_TEST_SV
`define CORE_TEST_SV

`include "types.svh"
`include "cordic_if.svh"
`include "core_monitor.svh"
`include "core_driver.svh"
`include "core_sequencer.svh"

// Main testbench
module testbench;
  localparam real p_CIRC_FACTOR = 0.6072529350092496;

  localparam real p_HYP_FACTOR = 1.2051363584457304;
  
  localparam bit p_SYSTEM = 1;				// 1 : Circular,   	0 : Hyperbolic
  localparam bit p_MODE = 0;				// 1 : Rotation, 	0 : Vectoring
  
  localparam p_INT_BITS = p_SYSTEM ? 0 : 3; // Number of bits for integer part

  typedef number #(32, p_INT_BITS)  num_type;
  typedef angle #(32) 	            ang_type;

  // CORDIC-controller interface
  cordic_if #(32) intf();
  
  core_monitor #(32, p_INT_BITS) mon 	= new(intf.controller);
  
  core_sequencer #(32, p_INT_BITS) seq	= new(intf.controller);
    
  // Initializing the CORDIC core
  cordic #(.p_WIDTH(32)) dut (
    intf.core
  );

  // Event for triggering a CORDIC iteration
  event e_sync;

  // Trigger CORDIC event
  always #2 ->e_sync;

  num_type init_x     = new(0);   // Initial y value
  num_type init_y     = new(0);   // Initial x value
  ang_type init_angle = new(0);		// Initial angle value
  
  real x_exp, y_exp, z_exp;       // Expected output values
  
  initial begin
    // Dump to VCD file
    $dumpvars(0);
    $dumpfile("dump.vcd");
	
    @e_sync #1;
    
    if(p_SYSTEM) begin
      if(p_MODE) begin
        $display("Circular rotation test");
      end else begin
        $display("Circular vectoring test");
      end
    end else begin
      if(p_MODE) begin
        $display("Hyperbolic rotation test");
      end else begin
        $display("Hyperbolic vectoring test");
      end
    end
    
    for(int iter1 = 0; iter1 < 10; iter1++) begin
      $display("----------------------------------------");
      $display(" Test no : %d", iter1);

      /*
      if(p_SYSTEM) begin
        if(p_MODE) begin
          // Circlar rotation
          init_x.set_real(p_CIRC_FACTOR);
          init_y.set_real(0);
          init_angle.set_deg(45);
        end else begin
          // Circular vectoring
          init_x.set_real(0);
          init_y.set_real(0.1);
          init_angle.set_deg(0);
        end
      end else begin
        if(p_MODE) begin
          // Hyperbolic rotation
          init_x.set_real(p_HYP_FACTOR);
          init_y.set_real(0);
          init_angle.set_deg(23);      
        end else begin
          // Hyperbolic vectoring
          init_x.set_real(1);
          init_y.set_real(0.5);
          init_angle.set_deg(0);
        end
      end
      */

      // Randomize x and y values
	  init_x.randomize();
      init_y.randomize();
      
      // Randomize angle for rotation mode and set to zero for vectoring mode  
      if(p_MODE) begin
        init_angle.randomize();
        while($abs(init_angle.val_deg) > 90)
          init_angle.randomize();
      end else begin
        init_angle.set_deg(0);
      end
      
      // Display final CORDIC state
      $display("Initial  : %10f, %10f, %10f", init_x.val, init_y.val, init_angle.val_deg);
      
      // Check validity and find expected values
      if(p_SYSTEM) begin
        if(p_MODE) begin
          // Circular rotation
          x_exp = (init_x.val * $cos(init_angle.val_rad) - init_y.val * $sin(init_angle.val_rad)) / p_CIRC_FACTOR;
          y_exp = (init_y.val * $cos(init_angle.val_rad) + init_x.val * $sin(init_angle.val_rad)) / p_CIRC_FACTOR;
          z_exp = 0;
        end else begin
          // Circular vectoring
          x_exp = (init_x.val ** 2 + init_y.val ** 2) ** 0.5 / p_CIRC_FACTOR;
          y_exp = 0;
          z_exp = init_angle.val_deg + ($atan2(init_y.val, init_x.val) * 180 / $acos(-1));
        end      
      end else begin
        if(p_MODE) begin
          // Hyperbolic rotation
          x_exp = (init_x.val * $cosh(init_angle.val_rad) + init_y.val * $sinh(init_angle.val_rad)) / p_HYP_FACTOR;
          y_exp = (init_y.val * $cosh(init_angle.val_rad) + init_x.val * $sinh(init_angle.val_rad)) / p_HYP_FACTOR;
          z_exp = 0;
        end else begin
          // Hyperbolic vectoring
          if($abs(init_y.val) > $abs(init_x.val)) begin
            $display("abs(y) < abs(x) for hyperbolic vectoring");
            continue;
          end
          
          x_exp = $sqrt(init_x.val ** 2 - init_y.val ** 2) / p_HYP_FACTOR;
          y_exp = 0;
          z_exp = init_angle.val_deg + ($atanh(init_y.val / init_x.val) * 180 / $acos(-1));
        end     
      end

      seq.set_system(p_SYSTEM);
      seq.set_mode(p_MODE);
      seq.reset(init_x.val, init_y.val, init_angle.val_deg);   

      #1;

      // Perform CORDIC iterations (rotation/vectoring)
      for(int iter2 = 0; iter2 < 25; iter2++) begin
        //$display("%8d : %10f, %10f, %10f", iter2, seq.x_num.val, seq.y_num.val, seq.z_ang.val_deg);
        if(seq.next_iter()) begin
          $display("Overflow detected after iteration %2d", iter2);
        end
        #1;
      end

      // Display final CORDIC state
      $display("Final    : %10f, %10f, %10f", seq.x_num.val, seq.y_num.val, seq.z_ang.val_deg);
      
      // Compare with expected results
      $display("Expected : %10f, %10f, %10f", x_exp, y_exp, z_exp);

      $display("Error    : %e, %e, %f deg", seq.x_num.val - x_exp, seq.y_num.val - y_exp, seq.z_ang.val_deg - z_exp);
    end
	
 	#10 $finish;								// Finish simulation
  end  
endmodule

`endif
