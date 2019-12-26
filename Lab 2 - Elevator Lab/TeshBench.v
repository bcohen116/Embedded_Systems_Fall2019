`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2019 04:46:33 PM
// Design Name: 
// Module Name: TeshBench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TestBench;
    //Inputs
    reg clk = 0;
    reg [3:0] OutsideSelectedFloor;
    reg up;
    reg down;
    reg update;
    reg [4:0] InsideDesiredFloor;
    //Outputs
    wire [3:0] DirectionState;
    wire [6:0] DisplayFloor;


//UUT

Lab2Elevator uut(
    .clk(clk),
    .OutsideSelectedFloor(OutsideSelectedFloor),
    .up(up),
    .down(down),
    .update(update),
    .InsideDesiredFloor(InsideDesiredFloor),
    //Outputs
    .DirectionState(DirectionState),
    .DisplayFloor(DisplayFloor)
);

always begin
 //Simulate the clock
 #10 clk = 1;
 #10 clk = 0;
 end

// Add stimulus here
initial begin
    update = 1'b0;
    OutsideSelectedFloor = 0;
    up = 0;
    down = 0;
    InsideDesiredFloor = 0;
    
    // Request the elevator to pick someone up on the 1st floor going up
//    OutsideSelectedFloor = 4'b0000;
//    up = 1'b1;
//    update = 1'b1;
//    #20 update = 1'b0;
//    #200
//    OutsideSelectedFloor = 4'b0100;
//    up = 1'b0;
//    down = 1'b1;
//    update = 1'b1;
//    #20 down = 1'b0;
//    update = 1'b0;

#200
InsideDesiredFloor = 5'b00011;
update = 1'b1;
#20 update = 1'b0;
#2600000010
InsideDesiredFloor = 5'b00000;
update = 1'b1;
#20 update = 1'b0;

    
//    #200
//    // Testing 
//    OutsideSelectedFloor = 4'b0011;
//    down = 1'b0;
//    up = 1'b1;
//    InsideDesiredFloor = 2;
    
//    #200
//    up = 1'b0;
    //#26000010 $finish;
    
end
    
endmodule
