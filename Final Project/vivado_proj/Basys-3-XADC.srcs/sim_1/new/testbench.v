`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2019 06:31:56 PM
// Design Name: 
// Module Name: testbench
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


module testbench;
    reg CLK100MHZ;
//    reg levelBtn;
    reg btnR;
    reg btnC;
    reg btnL;
    reg btnU;
    reg btnD;
    wire [15:0] led;
    
    
XADCdemo uut (
    .CLK100MHZ(CLK100MHZ),
    //.levelBtn(levelBtn),
    .led(led),
    .btnR(btnR),
    .btnC(btnC),
    .btnL(btnL),
    .btnU(btnU),
    .btnD(btnD)
);
    
    
 always begin
 //Simulate the clock
    #10 CLK100MHZ = 1;
    #10 CLK100MHZ = 0;
 end
 
 
 initial begin
//    levelBtn = 1;
//    #25
//    levelBtn = 0;
//    #1000000
//    levelBtn = 1;
//    #25
//    levelBtn = 0;
//    #1000000
//    levelBtn = 1;
//    #25
//    levelBtn = 0;
//    #1000000
//    levelBtn = 1;
//    #25
//    levelBtn = 0;
//    #1000000
//    levelBtn = 1;
//    #25
//    levelBtn = 0;

    btnD = 1;
    #25 btnD = 0;
    

    end

endmodule
