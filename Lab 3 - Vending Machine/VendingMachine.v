`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// 
// 
//////////////////////////////////////////////////////////////////////////////////


module VendingMachine(
    input clk,
    input [7:0] Selection,
    input quarterBtn,
    input dollarBtn,
    input cardBtn,
    input changeBtn,
    input buyBtn,
    output [5:0] Despensing,
    output reg [3:0] Anode_Activate, // anode signals of the 7-segment LED display
    output reg [7:0] LED_out// cathode patterns of the 7-segment LED display
    );
    //...................................
    reg [3:0] LED_BCD;
    reg [27:0] waittime = 0;
    reg [60:0] waittime2 = 0;
    reg [3:0] Seg1 = 0;
    reg [3:0] Seg2 = 0;
    reg [3:0] Seg3 = 0;
    reg [3:0] Seg4 = 0;
    reg [7:0] RegSelection = 0;
    reg [5:0] RegDespensing = 0;
    reg [2:0] State;
    reg [6:0] productPrices [7:0]; //Prices of each product
    reg [6:0] productQuantity [7:0]; //How much product is left in the machine
    reg [64:0] moneyInput = 0;
    reg [2:0] bearcatCardUsed = 0; //0 = no card input, 1 = card input, 2 = card declined
    reg [1:0] dotNeeded = 0;
    integer debouncer = 0;
    integer debouncer2 = 0;
    integer debouncer3 = 0;
    integer debouncer4 = 0;
    integer debouncer5 = 0;
    integer moneyInputInt = 0;
    integer SelectionInt = 0;
    
    
    reg [1:0] initialize = 0;
    //...................................
        
        
    always @(posedge clk)
    begin

        if (initialize == 0)
        begin
            //First time the program runs, setup variables
            productPrices[0] = 50;
            productPrices[1] = 50;
            productPrices[2] = 75;
            productPrices[3] = 75;
            productPrices[4] = 125;
            productPrices[5] = 125;
            productPrices[6] = 125;
            productPrices[7] = 125;
            
            productQuantity[0] = 10;
            productQuantity[1] = 10;
            productQuantity[2] = 50;
            productQuantity[3] = 0;
            productQuantity[4] = 5;
            productQuantity[5] = 10;
            productQuantity[6] = 2;
            productQuantity[7] = 10;
            initialize = 1;
        end
        
        
        if (quarterBtn == 1)begin
            if (debouncer == 13000000)begin
                //User input a quarter, add to total money put in machine
                moneyInput = moneyInput + 25;
                moneyInputInt = moneyInput;
                Seg1 = (moneyInputInt / (10 ** 3)) % 10;
                Seg2 = (moneyInputInt / (10 ** 2)) % 10;
                Seg3 = (moneyInputInt / (10 ** 1)) % 10;
                Seg4 = (moneyInputInt / (10 ** 0)) % 10; 
                debouncer = debouncer + 1;
            end
            else if (debouncer < 13000000)begin
                //counter to debounce the button
                debouncer = debouncer + 1;
            end
        end
        else begin
            debouncer = 0;
        end
        
        if (dollarBtn == 1)begin
            if (debouncer2 == 13000000)begin
                //User input a dollar, add to total money put in machine
                moneyInput = moneyInput + 100;
                moneyInputInt = moneyInput;
                Seg1 = (moneyInputInt / (10 ** 3)) % 10;
                Seg2 = (moneyInputInt / (10 ** 2)) % 10;
                Seg3 = (moneyInputInt / (10 ** 1)) % 10;
                Seg4 = (moneyInputInt / (10 ** 0)) % 10; 
                debouncer2 = debouncer2 + 1;
            end
            else if (debouncer2 < 13000000) begin
                //counter to debounce the button
                debouncer2 = debouncer2 + 1;
            end
        end
        else begin
            debouncer2 = 0;
        end
        
        if (cardBtn == 1)begin
            if (debouncer3 == 13000000)begin
                //User input a bearcat card, set register to denote that state
                bearcatCardUsed = 1;
                //Display "card" on the display to show card was accepted
                Seg1 = 11;
                Seg2 = 12;
                Seg3 = 13;
                Seg4 = 14;  
                debouncer3 = debouncer3 + 1;
            end
            else if (debouncer3 < 13000000) begin
                //counter to debounce the button
                debouncer3 = debouncer3 + 1;
            end
        end
        else begin
            debouncer3 = 0;
        end
        
        if (changeBtn == 1)begin
            if (debouncer4 == 13000000)begin
                //User requested change
                moneyInput = 0;
                Seg1 = 0;
                Seg2 = 0;
                Seg3 = 0;
                Seg4 = 0;  
                debouncer4 = debouncer4 + 1;
            end
            else if (debouncer4 < 13000000) begin
                //counter to debounce the button
                debouncer4 = debouncer4 + 1;
            end
        end
        else begin
            debouncer4 = 0;
        end
        
         if (buyBtn == 1 || waittime2 > 0)begin
            if (debouncer5 == 13000000)begin
                //Check if they put in enough money for the item they tried to pick, also if there is enough of the product in the machine
                SelectionInt = Selection;
                if((moneyInput >= productQuantity[SelectionInt] || bearcatCardUsed == 1) && productQuantity[SelectionInt] > 0)
                begin
                    //Enough money was found, dispense item
                    waittime2 = waittime2 + 1;
                    if(waittime2 ==124990000)
                    begin
                        RegDespensing[0] = 1;
                    end
                    else if(waittime2 ==249990000)
                    begin
                        RegDespensing[1] = 1;
                    end
                    else if(waittime2 ==374990000)
                    begin
                        RegDespensing[2] = 1;
                    end
                    else if(waittime2 ==499990000)
                    begin
                        RegDespensing[3] = 1;
                    end
                    else if(waittime2 ==524990000)
                    begin
                        RegDespensing[4] = 1;
                    end
                    else if(waittime2 >1000000000)
                    begin
                        //item finished dispensing
                        RegSelection = Selection;
                        RegDespensing = 6'b000000;
                        waittime2 = 0;
                        debouncer5 = 0;
                        if (bearcatCardUsed == 1)begin
                            //Bearcat card spent, reset register
                            bearcatCardUsed = 0;
                            
                            //Reset display to current balance
                            moneyInputInt = moneyInput;
                            Seg1 = (moneyInputInt / (10 ** 3)) % 10;
                            Seg2 = (moneyInputInt / (10 ** 2)) % 10;
                            Seg3 = (moneyInputInt / (10 ** 1)) % 10;
                            Seg4 = (moneyInputInt / (10 ** 0)) % 10; 
                        end
                        else begin
                            //product dispensed, remove cost from cash balance
                            moneyInput = moneyInput - productPrices[SelectionInt];
                            productQuantity[SelectionInt] =  productQuantity[SelectionInt] - 1;
                            moneyInputInt = moneyInput;
                            Seg1 = (moneyInputInt / (10 ** 3)) % 10;
                            Seg2 = (moneyInputInt / (10 ** 2)) % 10;
                            Seg3 = (moneyInputInt / (10 ** 1)) % 10;
                            Seg4 = (moneyInputInt / (10 ** 0)) % 10; 
                        end
                        
                    end
                end
                else if (productQuantity[SelectionInt] == 0 || moneyInput < productQuantity[SelectionInt]) begin
                    //Not enough product, display "oops"
                    Seg1 = 0;
                    Seg2 = 0;
                    Seg3 = 10;
                    Seg4 = 5;   
                end
                //debouncer5 = debouncer5 + 1;
            end
            else if (debouncer5 < 13000000) begin
                //counter to debounce the button
                debouncer5 = debouncer5 + 1;
            end
        end
        else begin
            debouncer5 = 0;
        end
        
        
        
        if(waittime ==12499)
        begin
            Anode_Activate = 4'b0111; 
            // activate LED1 and Deactivate LED2, LED3, LED4
            dotNeeded = 0;
            LED_BCD = Seg1;
        end
        else if(waittime ==24999)
        begin
            Anode_Activate = 4'b1011; 
            dotNeeded = 1;
            LED_BCD = Seg2;
        end
        else if(waittime ==37499)
        begin
            Anode_Activate = 4'b1101; 
            dotNeeded = 0;
            LED_BCD = Seg3;
        end
         else if(waittime ==49999)
        begin
            Anode_Activate = 4'b1110; 
            dotNeeded = 0;
            LED_BCD = Seg4;
            waittime = 0;
        end
        waittime = waittime + 1;
    end
    
    always@(*)
    begin
        if (dotNeeded == 1)begin
            case(LED_BCD)
                5'b00000: LED_out  = 8'b00000001; // "0"  
                5'b00001: LED_out  = 8'b01001111; // "1" 
                5'b00010: LED_out  = 8'b00010010; // "2" 
                5'b00011: LED_out  = 8'b00000110; // "3" 
                5'b00100: LED_out  = 8'b01001100; // "4" 
                5'b00101: LED_out  = 8'b00100100; // "5" 
                5'b00110: LED_out  = 8'b00100000; // "6" 
                5'b00111: LED_out  = 8'b00001111; // "7" 
                5'b01000: LED_out  = 8'b00000000; // "8"  
                5'b01001: LED_out  = 8'b00000100; // "9" 
                5'b01010: LED_out  = 8'b10011000; // "P"
                5'b01011: LED_out  = 8'b00110001; // "c"
                5'b01100: LED_out  = 8'b00000010; // "a"
                5'b01101: LED_out  = 8'b01111010; // "r"
                5'b01110: LED_out  = 8'b01000010; // "d"
                default: LED_out  = 8'b01111111; // "0"
            endcase
        end
        else begin
            case(LED_BCD)
                5'b00000: LED_out  = 8'b10000001; // "0"  
                5'b00001: LED_out  = 8'b11001111; // "1" 
                5'b00010: LED_out  = 8'b10010010; // "2" 
                5'b00011: LED_out  = 8'b10000110; // "3" 
                5'b00100: LED_out  = 8'b11001100; // "4" 
                5'b00101: LED_out  = 8'b10100100; // "5" 
                5'b00110: LED_out  = 8'b10100000; // "6" 
                5'b00111: LED_out  = 8'b10001111; // "7" 
                5'b01000: LED_out  = 8'b10000000; // "8"  
                5'b01001: LED_out  = 8'b10000100; // "9" 
                5'b01010: LED_out  = 8'b10011000; // "P"
                5'b01011: LED_out  = 8'b10110001; // "c"
                5'b01100: LED_out  = 8'b10000010; // "a"
                5'b01101: LED_out  = 8'b11111010; // "r"
                5'b01110: LED_out  = 8'b11000010; // "d"
                default: LED_out  = 8'b11111111; // "0"
            endcase
        end
      
    end
    
assign Despensing = RegDespensing;
    
endmodule
