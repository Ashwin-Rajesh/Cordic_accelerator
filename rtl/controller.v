`include "BusInterface.svh"

    // ControlRegister : Upper 16 Flags
    //                 : Lower 16 Control Bits

    // Control  0       : Start
    //          1       : Stop
    //          2       : p_ROTATION Mode
    //          3       : p_ROTATION System 
    //          4       : Error Interrupt Enable
    //          5       : Result Interrupt Enable
    //          6       : Overflow Stop Enable
    //          7       : Z Overflow stop Enable
    //          12, 8   : Number of Iteration

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
    BusInterface.controller busPort,
    CordicInterface.controller cordicPort,
    lutOffset, lutAngle, lutSystem
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

    localparam p_CNTRL_START = 0;
    localparam p_CNTRL_STOP = 1;
    localparam p_CNTRL_ROT_MODE = 2;
    localparam p_CNTRL_ROT_SYS = 3;
    localparam p_CNTRL_ERR_INT_EN = 4;
    localparam p_CNTRL_RSLT_INT_EN = 5;
    localparam p_CNTRL_OV_ST_EN = 6;
    localparam p_CNTRL_Z_OV_ST_EN = 7;
    localparam p_CNTRL_ITER_L = 8;
    localparam p_CNTRL_ITER_H = 12;
    
    localparam p_FLAG_READY = 16;
    localparam p_FLAG_INP_ERR = 17;
    localparam p_FLAG_OV_ERR = 18;
    localparam p_FLAG_X_OV_ERR = 19;
    localparam p_FLAG_Y_OV_ERR = 20;
    localparam p_FLAG_Z_OV_ERR = 21;
    localparam p_FLAG_ELAPS_ITER_L = 22;
    localparam p_FLAG_ELAPS_ITER_H = 26;
    localparam p_FLAG_OV_ITER_L = 27;
    localparam p_FLAG_OV_ITER_H = 31;

    input [p_WIDTH - 1 : 0 ] lutAngle;
    output wire [p_ANGLE_ADDR_WIDTH - 1:0] lutOffset;
    output wire lutSystem;

    reg [1:0] controllerState = p_IDLE;
    reg [1:0] nextState;
    reg [31:0] nextControlRegister;

    reg [31 : 0] controlRegister = {
        5'b0, 5'b0, 0, 0, 0, 0, 0, 1, 3'b0, 5'd31, 1, 1, 1, 1, 0, 0, 0, 0
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

    reg rotationDir = 0;

    reg [p_WIDTH - 1 : 0] nextX, nextY, nextZ;
    reg nextCntrlWrEn;
    reg nextInt;
    reg nextRotDir;

    wire [p_HALFWORD - 1 : 0] flagUpper;
    wire [p_HALFWORD - 1 : 0] controlLower;

    assign busPort.controlRegisterOutput = controlRegister;

    assign busPort.xResult = xValue;
    assign busPort.yResult = yValue;
    assign busPort.zResult = zValue;
    assign busPort.controlRegisterWriteEnable = contrlWriteEn;
    assign busPort.interrupt = interrupt;

    assign lutOffset = controlRegister[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L];
    assign lutSystem = controlRegister[p_CNTRL_ROT_SYS];

    assign p_CORDICPort.rotationSystem = controlRegister[p_CNTRL_ROT_SYS];
    assign p_CORDICPort.rotationAngle = lutAngle;
    assign p_CORDICPort.shiftAmount = controlRegister[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L];

    assign p_CORDICPort.rotationDir = rotationDir;
    assign p_CORDICPort.xPrev = xValue;
    assign p_CORDICPort.yPrev = yValue;
    assign p_CORDICPort.zPrev = zValue;

    wire clk;
    assign clk = busPort.clk;

    always @ (*) begin

        nextX = xValue;
        nextY = yValue;
        nextZ = zValue;
        nextControlRegister = controlRegister;          
        nextCntrlWrEn = contrlWriteEn;
        nextInt = interrupt;

        nextRotDir = rotationDir;

        nextState = controllerState;

        if (busPort.rst) begin

            nextControlRegister = {
                5'b0, 5'b0, 0, 0, 0, 0, 0, 1, 3'b0, 5'd31, 1, 1, 1, 1, 0, 0, 0, 0
            };

            nextX = 32'h0;
            nextY = 32'h0;
            nextZ = 32'h0;
            nextCntrlWrEn = 1'b1;
            nextInt = 1'b0;

            nextRotDir = 0;

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
                            5'b0, 5'b0, 0, 0, 0, 0, 0, 0, 3'b0, 
                            busPort.controlRegisterInput[p_CNTRL_ITER_H : p_CNTRL_ITER_L], 
                            busPort.controlRegisterInput[p_CNTRL_Z_OV_ST_EN], 
                            busPort.controlRegisterInput[p_CNTRL_OV_ST_EN],
                            busPort.controlRegisterInput[p_CNTRL_RSLT_INT_EN], 
                            busPort.controlRegisterInput[p_CNTRL_ERR_INT_EN], 
                            busPort.controlRegisterInput[p_CNTRL_ROT_SYS], 
                            busPort.controlRegisterInput[p_CNTRL_ROT_MODE], 
                            0, 0
                        };
                        
                        nextCntrlWrEn = 1;

                        nextRotDir = 0;

                        nextState = p_PRE_C;
                                                
                    end
                end

                p_PRE_C: begin
                    nextCntrlWrEn = 0;
                    
                    nextRotDir = controlRegister[p_CNTRL_ROT_MODE];
                    nextState = p_CORDIC;
                    
                    if(controlRegister[p_CNTRL_ROT_SYS]) begin
                        nextControlRegister[p_FLAG_ELAPS_ITER_H: p_FLAG_ELAPS_ITER_L] = 5'b00000;
                    end else begin
                        nextControlRegister[p_FLAG_ELAPS_ITER_H: p_FLAG_ELAPS_ITER_L] = 5'b00001;
                    end

                    if (controlRegister[p_CNTRL_ROT_SYS]) begin
                        if (controlRegister[p_CNTRL_ROT_MODE]) begin
                            if (zValue > p_RIGHT_ANGLE) begin
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
                        if(xValue[31] or (absY > xValue)) begin
                            nextControlRegister[p_FLAG_INP_ERR] = 1;
                            nextState = p_POST_C;
                        end
                    end

                end

                p_CORDIC: begin

                    nextControlRegister[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L] 
                            = controlRegister[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L] + 1;

                    if(~controlRegister[p_FLAG_OV_ERR]) begin
                        nextControlRegister[p_FLAG_OV_ITER_H:p_FLAG_OV_ITER_L]
                                = controlRegister[p_FLAG_OV_ITER_H:p_FLAG_OV_ITER_L] + 1;
                    end
                    
                    nextX = cordicPort.xResult;
                    nextY = cordicPort.yResult;
                    nextZ = cordicPort.zResult;
                    nextControlRegister[p_FLAG_X_OV_ERR] = cordicPort.xOverflow;
                    nextControlRegister[p_FLAG_Y_OV_ERR] = cordicPort.yOverflow;
                    nextControlRegister[p_FLAG_Z_OV_ERR] = cordicPort.zOverflow;
                    nextControlRegister[p_FLAG_OV_ERR] 
                        = nextControlRegister[p_FLAG_X_OV_ERR] or nextControlRegister[p_FLAG_Y_OV_ERR]
                            or nextControlRegister[p_FLAG_Z_OV_ERR];

                    nextState = p_CORDIC;

                    if(busPort.controlRegisterInput[p_CNTRL_STOP]) begin
                        nextState = p_POST_C;
                    end

                    if(controlRegister[p_CNTRL_OV_ST_EN]) begin
                        if(controlRegister[p_FLAG_X_OV_ERR] or controlRegister[p_FLAG_Y_OV_ERR]) begin
                            nextState = p_POST_C;
                        end
                        if(controlRegister[p_CNTRL_Z_OV_ST_EN] and controlRegister[p_FLAG_Z_OV_ERR]) begin
                            nextState = p_POST_C;
                        end
                    end

                    if(controlRegister[p_CNTRL_ITER_H:p_CNTRL_ITER_L] 
                        == nextControlRegister[p_FLAG_ELAPS_ITER_H:p_FLAG_ELAPS_ITER_L]) begin
                        nextState = p_POST_C;
                    end
                end

                
                default: 
            endcase 
        end
    end
endmodule
