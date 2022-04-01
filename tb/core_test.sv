`ifndef CORE_TEST_SV
`define CORE_TEST_SV

`include "types.svh"
`include "cordic_if.svh"
`include "core_monitor.svh"
`include "core_driver.svh"
`include "core_sequencer.svh"

typedef number #(32, 0) fixedpt_1;
typedef number #(32, 3) fixedpt_2;
typedef angle #(32) 	ang_type;

// Main testbench
module testbench;
  real p_CIRC_FACTOR = 0.6072529350092496;

  real p_HYP_FACTOR = 1.2051363584457304;

  bit r_mode = 0;
  bit r_mode_control = 0;
  
  // CORDIC-controller interface
  cordic_if #(32) intf();
  
  // Monitors
  core_monitor #(32, 0) monitor1 = new(intf.controller);	// For circular mode
  core_monitor #(32, 3) monitor2 = new(intf.controller);	// For hyperbolic mode

  core_sequencer #(32, 0) seq1 = new(intf.controller);

  core_sequencer #(32, 3) seq2 = new(intf.controller);
  
  // Initializing the CORDIC core
  cordic #(.p_WIDTH(32)) dut (
    intf.core
  );

  // Event for triggering a CORDIC iteration
  event e_sync;

  // Trigger CORDIC event
  always #2 ->e_sync;

  fixedpt_1 num1_x = new(0);
  fixedpt_1 num1_y = new(0);

  fixedpt_2 num2_x = new(0);
  fixedpt_2 num2_y = new(0);
  
  ang_type init_angle = new(0);		// Input angle

  ang_type ang_obj = new(0);		// Temporary variable to read from CORDIC outputs
  
  real x_exp, y_exp, z_exp;
  
  initial begin
    $dumpvars(0);
    $dumpfile("dump.vcd");
	
    @e_sync #1;
    
    r_mode = 1;			// Circular mode
    //r_mode = 0;		// Hyperbolic mode
    
    //r_mode_control = 1;	// Rotation mode
    r_mode_control = 0;	// Vectoring mode
    
    if(r_mode) begin
      if(r_mode_control) begin
        $display("Circular rotation");
        // Circular rotation mode initial data settings
        num1_x.set_real(p_CIRC_FACTOR);
        num1_y.set_real(0);
        init_angle.set_deg(45);
        
        x_exp = (num1_x.val * $cos(init_angle.val_rad) - num1_y.val * $sin(init_angle.val_rad)) / p_CIRC_FACTOR;
        y_exp = (num1_y.val * $cos(init_angle.val_rad) + num1_x.val * $sin(init_angle.val_rad)) / p_CIRC_FACTOR;
        z_exp = 0;
      end else begin
        $display("Circular vectoring");
        // Circular vectoring mode initial data settings
        num1_x.set_real(0);
        num1_y.set_real(0.1);
        init_angle.set_deg(0);
        
        x_exp = (num1_x.val ** 2 + num1_y.val ** 2) ** 0.5 / p_CIRC_FACTOR;
        y_exp = 0;
        z_exp = init_angle.val_deg + ($atan2(num1_y.val, num1_x.val) * 180 / $acos(-1));
      end
      seq1.set_system(r_mode);
      seq1.set_mode(r_mode_control);
    
	  seq1.reset(num1_x.val, num1_y.val, init_angle.val_deg);        
	end else begin
      if(r_mode_control) begin
        $display("Hyperbolic rotation");
        // Hyperbolic rotation mode initial data settings
        num2_x.set_real(p_HYP_FACTOR);
        num2_y.set_real(0);
        init_angle.set_deg(23);      
        
        x_exp = (num2_x.val * $cosh(init_angle.val_rad) + num2_y.val * $sinh(init_angle.val_rad)) / p_HYP_FACTOR;
        y_exp = (num2_y.val * $cosh(init_angle.val_rad) + num2_x.val * $sinh(init_angle.val_rad)) / p_HYP_FACTOR;
        z_exp = 0;
      end else begin
        $display("Hyperbolic vectoring");
        // Hyperbolic vectoring mode initial data settings
        num2_x.set_real(1);
        num2_y.set_real(0.5);
        init_angle.set_deg(0);
        
        x_exp = $sqrt(num2_x.val ** 2 - num2_y.val ** 2) / p_HYP_FACTOR;
        y_exp = 0;
        z_exp = init_angle.val_deg + ($atanh(num2_y.val / num2_x.val) * 180 / $acos(-1));
      end
      seq2.set_system(r_mode);
      seq2.set_mode(r_mode_control);
    
      seq2.reset(num2_x.val, num2_y.val, init_angle.val_deg);        
	end

    #1;
    
    // Perform CORDIC iterations (rotation/vectoring)
    for(int i = 0; i < 25; i++) begin
      if(r_mode) begin
        $display("%8d : %10f, %10f, %10f", i, seq1.x_num.val, seq1.y_num.val, seq1.z_ang.val_deg);
        if(seq1.next_iter()) begin
          $display("Overflow detected after iteration %2d", i);
          break;
        end
      end else begin
        $display("%8d : %10f, %10f, %10f", i, seq2.x_num.val, seq2.y_num.val, seq2.z_ang.val_deg);
        if(seq2.next_iter()) begin
          $display("Overflow detected after iteration %2d", i);
          break;
        end
      end
	  #1;
    end

    // Display final CORDIC state
    if(r_mode) begin
      $display("Final    : %10f, %10f, %10f", seq1.x_num.val, seq1.y_num.val, seq1.z_ang.val_deg);
    end else begin
      $display("Final    : %10f, %10f, %10f", seq2.x_num.val, seq2.y_num.val, seq2.z_ang.val_deg);
    end
    
    // Compare with expected results
    $display("Expected : %10f, %10f, %10f", x_exp, y_exp, z_exp);
    
    $display("Error :");
    if(r_mode)
      $display("%e, %e, %f deg", seq1.x_num.val - x_exp, seq1.y_num.val - y_exp, seq1.z_ang.val_deg - z_exp);
    else
      $display("%e, %e, %f deg", seq2.x_num.val - x_exp, seq2.y_num.val - y_exp, seq2.z_ang.val_deg - z_exp);
	
 	#10 $finish;								// Finish simulation
  end  
endmodule

`endif
