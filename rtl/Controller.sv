`include "BusInterface.svh"
`include "CordicInterface.svh"
`include "LutInterface.svh"

// ControlRegister : Upper 16 Flags
//                 : Lower 16 Control Bits

// Control  0       : Start
//          1       : Stop
//          2       : Rotation Mode
//          3       : Rotation System 
//          4       : Error Interrupt Enable
//          5       : Result Interrupt Enable
//          6       : Overflow Stop Enable
//          7       : Z Overflow stop Enable
//          12, 8   : Number of Iteration
//          13      : Z Overflow Report Enable.

// Flags    16      : Ready
//          17      : Input Error
//          18      : Overflow Error
//          19      : X Overflow 
//          20      : Y Overflow
//          21      : Z Overflow
//          26, 22  : Iterations Elapsed
//          31, 27  : Overflow Iteration

module Controller #(
  parameter 	p_WIDTH = 32,
  parameter   p_HALFWORD = 16,
  parameter   p_ANGLE_ADDR_WIDTH = 5
) (
  BusInterface.controller                 busPort,
  CordicInterface.controller              cordicPort,
  LutInterface.controller                 lutPort
);

  localparam p_IDLE = 2'b00;
  localparam p_PRE_C = 2'b01;
  localparam p_CORDIC = 2'b10;
  localparam p_POST_C = 2'b11;

  localparam p_CIRCULAR = 1'b1;
  localparam p_HYPERBOLIC = 1'b0;

  localparam p_VECTOR = 1'b0;
  localparam p_ROTATION = 1'b1;
  localparam p_RIGHT_ANGLE = 32'h40000000;
  localparam p_LOW_ANGLE = 32'h80000000;

  reg [1:0] controllerState = p_IDLE;
  reg [1:0] nextState;
  reg [31:0] nextControlRegister;

  reg [31 : 0] controlRegister = {
    5'b0, 5'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 2'b0, 1'b1, 5'd31, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0
  };

  reg [p_WIDTH - 1 : 0] xValue = 32'h0;
  reg [p_WIDTH - 1 : 0] yValue = 32'h0;
  reg [p_WIDTH - 1 : 0] zValue = 32'h0;

  wire [p_WIDTH - 1 : 0] negX, negY, rotZ, absY;

  assign negX = - xValue;
  assign negY = - yValue;
  assign absY = (yValue[31])? negY : yValue;
  assign rotZ[30:0] = zValue[30:0];
  assign rotZ[31] = ~zValue[31];
  reg contrlWriteEn = 1'b0;
  reg interrupt = 1'b0;

  reg [p_WIDTH - 1 : 0] nextX, nextY, nextZ;
  reg nextCntrlWrEn;
  reg nextInt;

  wire [p_HALFWORD - 1 : 0] flagUpper;
  wire [p_HALFWORD - 1 : 0] controlLower;

  assign busPort.controlRegisterOutput = controlRegister;

  assign busPort.xResult = xValue;
  assign busPort.yResult = yValue;
  assign busPort.zResult = zValue;
  assign busPort.controlRegisterWriteEnable = contrlWriteEn;
  assign busPort.interrupt = interrupt;

  assign lutPort.lutOffset = controlRegister[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L];
  assign lutPort.lutSystem = controlRegister[p_CNTRL_ROT_SYS];

  assign cordicPort.rotationSystem = controlRegister[p_CNTRL_ROT_SYS];
  assign cordicPort.rotationAngle = lutPort.lutAngle;
  assign cordicPort.shiftAmount = controlRegister[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L];

  // assign cordicPort.rotationDir = rotationDir;
  assign cordicPort.rotationDir = controlRegister[p_CNTRL_ROT_MODE] ? ~cordicPort.zPrev[p_WIDTH-1] : cordicPort.yPrev[p_WIDTH-1];
  assign cordicPort.xPrev = xValue;
  assign cordicPort.yPrev = yValue;
  assign cordicPort.zPrev = zValue;

  wire clk;
  assign clk = busPort.clk;

  always @ (*) begin

    nextX = xValue;
    nextY = yValue;
    nextZ = zValue;
    nextControlRegister = controlRegister;          
    nextCntrlWrEn = contrlWriteEn;
    nextInt = interrupt;

    nextState = controllerState;

    if (busPort.rst) begin

      nextControlRegister = {
              5'b0,   // Overflow iteration
              5'b0,   // Iteration elapsed
              1'b0,   // Z overflow
              1'b0,   // Y overflow
              1'b0,   // X overflow
              1'b0,   // Overflow Error
              1'b0,   // Input Error
              1'b1,   // Ready
              2'b0,   // Placeholder
              1'b1,   // Z overflow Report enable
              5'd31,  // Number of iterations
              1'b1,   // z overflow stop enable
              1'b1,   // Overflow stop enable
              1'b1,   // Result interrupt enable
              1'b1,   // Error interrupt enable
              1'b0,   // Rotation system (1 for circ, 0 for hyp)
              1'b0,   // Rotation mode (1 for rot, 0 for vect)
              1'b0,   // Stop
              1'b0    // Start
            };
      
      nextX = 32'h0;
      nextY = 32'h0;
      nextZ = 32'h0;
      nextCntrlWrEn = 1'b1;
      nextInt = 1'b0;

      nextState = p_IDLE;
    end else begin
      
      case (controllerState)
        p_IDLE : begin
          nextCntrlWrEn = 1'b0;
          nextInt = 1'b0;
          

          if (busPort.controlRegisterInput[p_CNTRL_START]) begin
            
            nextX = busPort.xInput;
            nextY = busPort.yInput;
            nextZ = busPort.zInput;

            nextControlRegister = {
              5'b0,                                                           // Overflow iteration
              5'b0,                                                           // Iteration elapsed
              1'b0,                                                           // Z overflow
              1'b0,                                                           // Y overflow
              1'b0,                                                           // X overflow
              1'b0,                                                           // Overflow Error
              1'b0,                                                           // Input Error
              1'b0,                                                           // Ready
              2'b0,                                                           // Placeholder
              busPort.controlRegisterInput[p_CNTRL_Z_OV_EN],                  // Z Overflow Report Enable
              busPort.controlRegisterInput[p_CNTRL_ITER_H : p_CNTRL_ITER_L],  // Number of iterations
              busPort.controlRegisterInput[p_CNTRL_Z_OV_ST_EN],               // z overflow stop enable
              busPort.controlRegisterInput[p_CNTRL_OV_ST_EN],                 // Overflow stop enable
              busPort.controlRegisterInput[p_CNTRL_RSLT_INT_EN],              // Result interrupt enable
              busPort.controlRegisterInput[p_CNTRL_ERR_INT_EN],               // Error interrupt enable
              busPort.controlRegisterInput[p_CNTRL_ROT_SYS],                  // Rotation system (1 for circ, 0 for hyp)
              busPort.controlRegisterInput[p_CNTRL_ROT_MODE],                 // Rotation mode (1 for rot, 0 for vect)
              1'b0,                                                           // Stop
              1'b0                                                            // Start
            };
            
            nextCntrlWrEn = 1'b1;

            nextState = p_PRE_C;
                        
          end
        end

        p_PRE_C: begin
          nextCntrlWrEn = 1'b0;
          
          nextState = p_CORDIC;
          
          if(controlRegister[p_CNTRL_ROT_SYS]) begin
            nextControlRegister[p_FLAG_ELAPS_ITER_H: p_FLAG_ELAPS_ITER_L] = 5'b00000;
          end else begin
            nextControlRegister[p_FLAG_ELAPS_ITER_H: p_FLAG_ELAPS_ITER_L] = 5'b00001;
          end

          if (controlRegister[p_CNTRL_ROT_SYS]) begin
            if (controlRegister[p_CNTRL_ROT_MODE]) begin
              if (zValue[p_WIDTH-1] ? zValue < -p_RIGHT_ANGLE: zValue > p_RIGHT_ANGLE) begin
                nextZ = rotZ;
                nextX = negX;
                nextY = negY;
              end
            end else begin
              if(xValue[31]) begin
                nextZ = rotZ;
                nextX = negX;
                nextY = negY;
              end
            end
          end

          if (~controlRegister[p_CNTRL_ROT_SYS]) begin
            if(xValue[31] || (absY > xValue)) begin
              nextControlRegister[p_FLAG_INP_ERR] = 1'b1;
              nextState = p_POST_C;
            end
          end

        end

        p_CORDIC: begin

          nextControlRegister[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L] 
              = controlRegister[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L] + 1'b1;

          if(~controlRegister[p_FLAG_OV_ERR]) begin
            nextControlRegister[p_FLAG_OV_ITER_H:p_FLAG_OV_ITER_L]
                = nextControlRegister[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L];
          end
          
          nextX = cordicPort.xResult;
          nextY = cordicPort.yResult;
          nextZ = cordicPort.zResult;
          
          if(~controlRegister[p_FLAG_X_OV_ERR]) nextControlRegister[p_FLAG_X_OV_ERR] = cordicPort.xOverflow;
          if(~controlRegister[p_FLAG_Y_OV_ERR]) nextControlRegister[p_FLAG_Y_OV_ERR] = cordicPort.yOverflow;
          if(~controlRegister[p_FLAG_Z_OV_ERR]) nextControlRegister[p_FLAG_Z_OV_ERR] = cordicPort.zOverflow;
          if(~controlRegister[p_FLAG_OV_ERR])   
            nextControlRegister[p_FLAG_OV_ERR] = nextControlRegister[p_FLAG_X_OV_ERR] 
                || nextControlRegister[p_FLAG_Y_OV_ERR] 
                || (nextControlRegister[p_FLAG_Z_OV_ERR] & nextControlRegister[p_CNTRL_Z_OV_EN]);

          nextState = p_CORDIC;

          if(busPort.controlRegisterInput[p_CNTRL_STOP]) begin
            nextState = p_POST_C;
            nextControlRegister[p_CNTRL_STOP] = 1'b0;
          end

          if(controlRegister[p_CNTRL_OV_ST_EN]) begin
            if(controlRegister[p_FLAG_X_OV_ERR] || controlRegister[p_FLAG_Y_OV_ERR]) begin
              nextState = p_POST_C;
            end
            if(controlRegister[p_CNTRL_Z_OV_ST_EN] && controlRegister[p_FLAG_Z_OV_ERR]) begin
              nextState = p_POST_C;
            end
          end

          if(controlRegister[p_CNTRL_ITER_H:p_CNTRL_ITER_L] 
            == nextControlRegister[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L]) begin
            nextState = p_POST_C;
          end

        end

        p_POST_C: begin
          nextState = p_IDLE;
          if (
            (
              (
                (
                  controlRegister[p_CNTRL_OV_ST_EN] && (
                    controlRegister[p_FLAG_X_OV_ERR] || controlRegister[p_FLAG_Y_OV_ERR]
                    || (
                      controlRegister[p_CNTRL_Z_OV_ST_EN] && controlRegister[p_FLAG_Z_OV_ERR]
                    )
                  )
                ) || controlRegister[p_FLAG_INP_ERR]
              ) && controlRegister[p_CNTRL_ERR_INT_EN] 
            ) || controlRegister[p_CNTRL_RSLT_INT_EN]
          ) begin
            nextInt = 1'b1;
          end
          nextCntrlWrEn = 1'b1;

          nextControlRegister[p_FLAG_READY] = 1'b1;
        end
      endcase 
    end
  end

  always @ (posedge clk) begin
    
    controllerState <= nextState;
    controlRegister <= nextControlRegister;
    xValue <= nextX;
    yValue <= nextY;
    zValue <= nextZ;
    contrlWriteEn <= nextCntrlWrEn;
    interrupt <= nextInt;
  end
endmodule
