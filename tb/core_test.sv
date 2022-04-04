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
  localparam bit p_MODE = 1;				// 1 : Rotation, 	0 : Vectoring
  
  localparam p_INT_BITS = p_SYSTEM ? 0 : 3; // Number of bits for integer part

  localparam p_LOG_TESTS = 0;
  localparam p_LOG_ITER  = 0;

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

  num_type init_x     = new(0);   // Initial y value
  num_type init_y     = new(0);   // Initial x value
  ang_type init_angle = new(0);		// Initial angle value
  
  real exp_x, exp_y, exp_z;       // Expected output values
  
  bit overflow = 0;
  
  real xInitHist[$],  yInitHist[$],   zInitHist[$];
  real xExpHist[$],   yExpHist[$],    zExpHist[$];
  real xErrorHist[$], yErrorHist[$],  zErrorHist[$];
  bit  validHist[$];
  int  idxHist[$];
  
  initial begin
    // Dump to VCD file
    $dumpvars(0);
    $dumpfile("dump.vcd");
	
    // Display system and mode in log
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
    
	// Run the tests
    for(int iter1 = 0; iter1 < 250; iter1++) begin
	  #10;
    
      if(p_LOG_TESTS) begin
        $display("----------------------------------------");
        $display(" Test no : %d", iter1);
      end

      overflow = 0;

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
      if(p_LOG_TESTS) $display("Initial  : %10f, %10f, %10f", init_x.val, init_y.val, init_angle.val_deg);
      
      // Check validity and find expected values
      if(p_SYSTEM) begin
        if(p_MODE) begin
          if($abs(init_angle.val_deg) > 99) begin
            if(p_LOG_TESTS) $display("abs(ang) < 99 for circular rotation");
            iter1--;
            continue;
          end
          
          // Circular rotation
          exp_x = (init_x.val * $cos(init_angle.val_rad) - init_y.val * $sin(init_angle.val_rad)) / p_CIRC_FACTOR;
          exp_y = (init_y.val * $cos(init_angle.val_rad) + init_x.val * $sin(init_angle.val_rad)) / p_CIRC_FACTOR;
          exp_z = 0;
        end else begin
          // Circular vectoring
          exp_x = (init_x.val ** 2 + init_y.val ** 2) ** 0.5 / p_CIRC_FACTOR;
          exp_y = 0;
          exp_z = init_angle.val_deg + ($atan2(init_y.val, init_x.val) * 180 / $acos(-1));

          if($abs(exp_z) > 99) begin
            if(p_LOG_TESTS) $display("abs(expected ang) < 99 for circular rotation");
            iter1--;
            continue;
          end  
          
          if(exp_x > num_type::max_val_real || exp_x < num_type::min_val_real  || exp_y > num_type::max_val_real || exp_y < num_type::min_val_real) begin
            if(p_LOG_TESTS) $display("Expected value will overflow");
            iter1--;
            continue;
          end
		end      
      end else begin
        if(p_MODE) begin
          if($abs(init_angle.val_deg) > 60) begin
            if(p_LOG_TESTS) $display("abs(ang) < 60 for hyperbolic rotation");
            iter1--;
            continue;
          end
          
          // Hyperbolic rotation
          exp_x = (init_x.val * $cosh(init_angle.val_rad) + init_y.val * $sinh(init_angle.val_rad)) / p_HYP_FACTOR;
          exp_y = (init_y.val * $cosh(init_angle.val_rad) + init_x.val * $sinh(init_angle.val_rad)) / p_HYP_FACTOR;
          exp_z = 0;
        end else begin
          // Hyperbolic vectoring
          if($abs(init_y.val) > $abs(init_x.val)) begin
            if(p_LOG_TESTS) $display("abs(y) < abs(x) for hyperbolic vectoring");
            iter1--;
            continue;
          end
          
          exp_x = $sqrt(init_x.val ** 2 - init_y.val ** 2) / p_HYP_FACTOR;
          exp_y = 0;
          exp_z = init_angle.val_deg + ($atanh(init_y.val / init_x.val) * 180 / $acos(-1));
        end     
      end

      seq.set_system(p_SYSTEM);
      seq.set_mode(p_MODE);
      seq.reset(init_x.val, init_y.val, init_angle.val_deg);   

      #1;

      // Perform CORDIC iterations (rotation/vectoring)
      for(int iter2 = 0; iter2 < 25; iter2++) begin
        if(p_LOG_ITER) $display("%8d : %10f, %10f, %10f", iter2, seq.x_num.val, seq.y_num.val, seq.z_ang.val_deg);
        if(seq.next_iter()) begin
          if(p_LOG_TESTS) $display("Overflow detected after iteration %2d", iter2);
          overflow = 1;
          // assert(exp_x > num_type::max_val_real || exp_x < num_type::min_val_real  || exp_y > num_type::max_val_real || exp_y < num_type::min_val_real);
          break;
        end
        #1;
      end

      // Display final CORDIC state
      if(p_LOG_TESTS) $display("Final    : %10f, %10f, %10f", seq.x_num.val, seq.y_num.val, seq.z_ang.val_deg);
      
      // Compare with expected results
      if(p_LOG_TESTS) $display("Expected : %10f, %10f, %10f", exp_x, exp_y, exp_z);

      if(p_LOG_TESTS) $display("Error    : %e, %e, %f deg", seq.x_num.val - exp_x, seq.y_num.val - exp_y, seq.z_ang.val_deg - exp_z);
            
      xInitHist.push_back(init_x.val);
      yInitHist.push_back(init_y.val);
      zInitHist.push_back(init_angle.val_deg);

      xExpHist.push_back(exp_x);
      yExpHist.push_back(exp_y);
      zExpHist.push_back(exp_z);
            
      xErrorHist.push_back($abs(seq.x_num.val     - exp_x));
      yErrorHist.push_back($abs(seq.y_num.val     - exp_y));
      zErrorHist.push_back($abs(seq.z_ang.val_deg - exp_z));

      validHist.push_back(~overflow);
      idxHist.push_back(iter1);
    end
    
    $display("%2s : %10s, %10s, %10s | %10s, %10s, %11s | %12s, %12s, %10s", "No", "init x", "init y", "init ang", "exp x", "exp y", "exp ang", "error x", "error y", "error ang");
    for(int iter3 = 0; iter3 < xErrorHist.size(); iter3++) begin
      $display("%2d : %10f, %10f, %10f | %10f, %10f, %11f | %12e, %12e, %10f : %2s", idxHist[iter3], xInitHist[iter3] , yInitHist[iter3], zInitHist[iter3], xExpHist[iter3], yExpHist[iter3], zExpHist[iter3], xErrorHist[iter3] , yErrorHist[iter3], zErrorHist[iter3], validHist[iter3] ? "OK" : "Overflow");
    end
    
    $display(" Error of x : %12e to %12e, avg %e", get_min(xErrorHist), get_max(xErrorHist), xErrorHist.sum() / xErrorHist.size());
    $display(" Error of y : %12e to %12e, avg %e", get_min(yErrorHist), get_max(yErrorHist), yErrorHist.sum() / yErrorHist.size());
    $display(" Error of z : %8f deg to %8f deg, avg %f deg", get_min(zErrorHist), get_max(zErrorHist), zErrorHist.sum() / zErrorHist.size());
    
 	#10 $finish;								// Finish simulation
  end  
  
  function real get_min(real inp[$]);
    real temp[$];
    temp = inp.min();
    if(temp.size() == 0)
      return 1.0/0;
    else
      return temp[0];
  endfunction
  
  function real get_max(real inp[$]);
    real temp[$];
    temp = inp.max();
    if(temp.size() == 0)
      return 1.0/0;
    else
      return temp[0];
  endfunction
endmodule

`endif
