`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/30/2019 06:30:57 PM
// Design Name: 
// Module Name: Lab2Elevator
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


module Lab2Elevator(
    input clk,
    input [3:0] CurrentFloor, // The current floor the outside up or down is pressed at
    input up,
    input down,
    input [4:0] InsideDesiredFloor, 
    output [3:0] DirectionState,
    output [6:0]DisplayFloor);
    //W4 V4 U4 U2 pins for 7segment display
    
    reg [3:0] DirectionStateReg; // Direction where the elevator is heading (up or down)
    reg [6:0] DisplayFloorReg; // Floor which the Elevator is currently at
    reg [1:0] ElevatorCurrentMovingState = 2; //Elevator moving state (up, down or stopped)
    reg [4:0] CurrentFloorElevatorIsAt = 1;
    reg [4:0] DesiredoutsideFloorSelectionStates = 0; // 5 bits to keep track of the outside selection for each floor
    reg [4:0] DesiredoutsideDirectionStates = 0; // 5 bits to specify the desired direction up or down on floors with pushed buttons (1 for up, 0 for down)
    reg [4:0] DesiredInsideStates = 0; // 1 means floor is desired, 1 bit for each floor
    //................
    
    reg [4:0] DesiredoutsideFloorSelectionStatesA3 = 0; 
    reg [4:0] DesiredoutsideDirectionStatesA3 = 0; 
    reg [4:0] DesiredInsideStatesA2 = 0; 
    
    //....................
    reg Boolean;
    reg temp;
    integer GoUpTo = 0;
    integer GoDownTo = 10;
    integer Counter = 10;
    integer waitCounter = 0;
    integer FloorCallingTheElevator = 0;
    integer SelectedFloorsToGoTo = 0;
    integer i;
    integer x;
    integer currentFloor = 0;
    
    parameter ZERO = 7'b0000001, ONE = 7'b1001111, TWO = 7'b0010010,
    THREE = 7'b0000110, FOUR = 7'b1001100,FIVE = 7'b0100100,
    SIX = 7'b0100000, SEVEN = 7'b0001111, EIGHT = 7'b0000000;
     
    
    always@(posedge clk) // Controls what the Elevator does and where to go
    begin
        DesiredInsideStates <= DesiredInsideStatesA2;
        DesiredoutsideDirectionStates <= DesiredoutsideDirectionStatesA3;
        DesiredoutsideFloorSelectionStates <= DesiredoutsideFloorSelectionStatesA3;
        case (ElevatorCurrentMovingState)
        0: // Going Down
            begin            
            
            if(waitCounter == 0)
            begin
                //Move the elevator one floor
                Counter = CurrentFloorElevatorIsAt;
                Counter = Counter - 1;
                CurrentFloorElevatorIsAt <= Counter;
                DirectionStateReg <= 0;
                $display("Current Floor: %d", CurrentFloorElevatorIsAt);
                //DisplayFloorReg = Counter;
            end
            
                //Check if the elevator needs to stop at this floor
                if((DesiredoutsideFloorSelectionStates[Counter] == 1 && (DesiredoutsideDirectionStates[Counter] == 0 || GoDownTo == Counter )) || DesiredInsideStates[Counter] == 1)
                begin
                    //Wait about 1 second so we can physically see the elevator at each floor it stops at
                    if( waitCounter <= 13000000)
                        begin
                            waitCounter <= waitCounter + 1;
                        end
                    else
                        begin
                            // Wait completed, remove floor from lists as we no longer need to move to it
                            waitCounter <= 0;
                            DesiredoutsideFloorSelectionStates[Counter] = 0;
                            DesiredoutsideFloorSelectionStatesA3[Counter] = 0;
                            DesiredoutsideDirectionStates[Counter] = 0;
                            DesiredoutsideDirectionStatesA3[Counter] = 0;
                            DesiredInsideStates[Counter] = 0;
                            DesiredInsideStatesA2[Counter] = 0;
                            GoDownTo = 10;
                        end
                end   
                else
                    begin
                        //Nothing was found directly below the current floor of the elevator,
                        //Check for any additional floors the elevator needs to move to
                        Boolean = 0;
                        for(i = 4; i >= 0; i = i - 1)begin
                            if (i < Counter)begin
                                if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 0 || GoDownTo == Counter )) || DesiredInsideStates[i] == 1)
                                    Boolean = 1; 
                            end
                            else if(i == Counter)begin
                                //If the elevator is currently on the same floor as the user requested floor, "open the door" by waiting about a second
                                 if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 0 || GoDownTo == Counter )) || DesiredInsideStates[i] == 1)
                                    begin
                                        if( waitCounter <= 13000000)
                                            begin
                                                waitCounter <= waitCounter + 1;
                                            end
                                        else
                                            begin
                                                // Wait completed, remove floor from lists as we no longer need to move to it
                                                waitCounter <= 0;
                                                DesiredoutsideFloorSelectionStates[Counter] = 0;
                                                DesiredoutsideFloorSelectionStatesA3[Counter] = 0;
                                                DesiredoutsideDirectionStates[Counter] = 0;
                                                DesiredoutsideDirectionStatesA3[Counter] = 0;
                                                DesiredInsideStates[Counter] = 0;
                                                DesiredInsideStatesA2[Counter] = 0;
                                                GoDownTo = 10;
                                            end
                                    end
                            end
                            
                        end 
                        if(Boolean == 0)
                            begin
                            //No more floors are requested below the elevator, move to "stopped" state so it can search for the next closest request
                            ElevatorCurrentMovingState <= 2;
                            end
                    end      
            end
            
        1: // Going Up
            begin
                if(waitCounter == 0)
                    begin
                        //Move the elevator one floor
                        Counter = CurrentFloorElevatorIsAt;
                        Counter = Counter + 1;
                        CurrentFloorElevatorIsAt = Counter;
                        DirectionStateReg <= 1;
                        $display("Current Floor (Up): %d", CurrentFloorElevatorIsAt);
                        //DisplayFloorReg = Counter;
                    end

                //Check if the elevator needs to stop at this floor
                if((DesiredoutsideFloorSelectionStates[Counter] == 1 && (DesiredoutsideDirectionStates[Counter] == 1 || GoUpTo == Counter )) || DesiredInsideStates[Counter] == 1)
                    begin
                        //Wait about 1 second so we can physically see the elevator at each floor it stops at
                        if( waitCounter <= 13000000)
                            begin
                                waitCounter <= waitCounter + 1;
                            end
                        else
                            begin
                                // Wait completed, remove floor from lists as we no longer need to move to it
                                waitCounter <= 0;
                                DesiredoutsideFloorSelectionStates[Counter] = 0;
                                DesiredoutsideFloorSelectionStatesA3[Counter] = 0;
                                DesiredoutsideDirectionStates[Counter] = 0;
                                DesiredoutsideDirectionStatesA3[Counter] = 0;
                                DesiredInsideStates[Counter] = 0;
                                DesiredInsideStatesA2[Counter] = 0;
                                GoUpTo = 10;
                            end
                    end   
                    else
                        begin
                            //Nothing was found directly above the current floor of the elevator,
                            //Check for any additional floors the elevator needs to move to
                            Boolean = 0;
                            for(i = 0; i < 5; i = i + 1)begin
                                if (i > Counter)begin
                                    if((DesiredoutsideFloorSelectionStates[i] == 1 && (DesiredoutsideDirectionStates[i] == 1|| GoUpTo == i )) || DesiredInsideStates[i] == 1)
                                    Boolean = 1; 
                                end
                            end 
                            if(Boolean == 0)
                            begin
                                //No more floors are requested above the elevator, move to "stopped" state so it can search for the next closest request
                                ElevatorCurrentMovingState <= 2;
                            end
                        end
            end
        2: //Elevator Stopped idle
            begin
                 currentFloor = CurrentFloorElevatorIsAt;
                 DirectionStateReg <= 3;
                 //Find the closest floor and go that direction
                 for (x = 1; x < 5; x = x + 1)
                 begin
                 //$display("x in stopped: %d", x);
                 $display("DesiredoutsideFloorSelectionStates[currentFloor + x]: %d", DesiredoutsideFloorSelectionStates[currentFloor + x] );
                 $display("DesiredInsideStates[currentFloor + x]: %d", DesiredInsideStates[currentFloor + x] );
                 $display("DesiredoutsideFloorSelectionStates[currentFloor - x]: %d", DesiredoutsideFloorSelectionStates[currentFloor - x] );
                 $display("DesiredInsideStates[currentFloor - x]: %d", DesiredInsideStates[currentFloor - x] );
                 $display("currentFloor - x >= 0: %d", currentFloor - x >= 0 );
                 $display("currentFloor + x < 5: %d", currentFloor + x < 5 );
                    //If elevator is on the bottom floor
                    if (currentFloor == 0)
                    begin
                        if (DesiredoutsideFloorSelectionStates[currentFloor + x] == 1  || DesiredInsideStates[currentFloor + x] == 1)
                        begin
                            ElevatorCurrentMovingState = 1;// change state to moving up
                            GoUpTo = currentFloor + x;
                            x <= 5; //End the for loop, we found a floor
                        end
                    end
                    //If the elevator is on the top floor
                    else if (currentFloor == 4)
                    begin
                        if (DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 || DesiredInsideStates[currentFloor - x] == 1)
                        begin
                            ElevatorCurrentMovingState = 0;//change state to moving down
                            GoDownTo = currentFloor - x;
                            x <= 5; //End the for loop, we found a floor
                        end
                    end
                    //Otherwise
                    else if ((currentFloor + x < 5 || currentFloor - x >= 0) && (DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 
                    || DesiredoutsideFloorSelectionStates[currentFloor + x] == 1 ||
                        DesiredInsideStates[currentFloor - x] == 1 ||
                        DesiredInsideStates[currentFloor + x] == 1))
                    begin
                        $display("Else if confirmed...");
                        //Check for out of bounds errors
                        if (currentFloor - x >= 0) begin
                             //find the first floor that needs to be moved to and go that direction
                            if (DesiredoutsideFloorSelectionStates[currentFloor - x] == 1 || DesiredInsideStates[currentFloor - x] == 1)
                                ElevatorCurrentMovingState = 0;//change state to moving down
                                GoDownTo = currentFloor - x;
                                x <= 5; //End the for loop, we found a floor
                        end
                        //Check for out of bounds errors
                        if(currentFloor + x < 5)begin
                            //find the first floor that needs to be moved to and go that direction
                            $display("Less than 5 confirmed...");
                            if (DesiredoutsideFloorSelectionStates[currentFloor + x] == 1 || DesiredInsideStates[currentFloor + x] == 1)
                                begin
                                    ElevatorCurrentMovingState = 1;//change state to moving up
                                    GoUpTo = currentFloor + x;
                                    $display("ElevatorCurrentMovingState %d", ElevatorCurrentMovingState);
                                    x <= 5; //End the for loop, we found a floor
                                end
                        end
                       
                    end
                 end
            end
        endcase
        
    
    end
    
    always@(InsideDesiredFloor) //inside of the Elevator
    begin
        //Find the floor the user requested
        SelectedFloorsToGoTo <= InsideDesiredFloor;
        DesiredInsideStatesA2 <= DesiredInsideStates;
        DesiredInsideStatesA2[SelectedFloorsToGoTo] <= 1;
    end
    
    always@(up or down) //Outside of the Elevator
    begin
        //Find the floor and direction the user wants to go to
        FloorCallingTheElevator = CurrentFloor;
        if(up)
            begin
               DesiredoutsideFloorSelectionStatesA3 <= DesiredoutsideFloorSelectionStates;
               DesiredoutsideFloorSelectionStatesA3[FloorCallingTheElevator] <= 1;
               DesiredoutsideDirectionStatesA3 <= DesiredoutsideDirectionStates;
               DesiredoutsideDirectionStatesA3[FloorCallingTheElevator] <= 1;
           end
        if(down)
            begin
                DesiredoutsideFloorSelectionStatesA3 <= DesiredoutsideFloorSelectionStates;
                DesiredoutsideFloorSelectionStatesA3[FloorCallingTheElevator] <= 1;
                DesiredoutsideDirectionStatesA3 <= DesiredoutsideDirectionStates;
                DesiredoutsideDirectionStatesA3[FloorCallingTheElevator] <= 0;
            end
    end
    
    //initialize outputs
    assign DirectionState = DirectionStateReg;
   
    
    
    always @(*)
    begin
         case(CurrentFloorElevatorIsAt)
         5'b00000: DisplayFloorReg = 7'b0000001; // "0"  
         5'b00001: DisplayFloorReg = 7'b1001111; // "1" 
         5'b00010: DisplayFloorReg = 7'b0010010; // "2" 
         5'b00011: DisplayFloorReg = 7'b0000110; // "3" 
         5'b00100: DisplayFloorReg = 7'b1001100; // "4" 
         5'b00101: DisplayFloorReg = 7'b0100100; // "5" 
         5'b00110: DisplayFloorReg = 7'b0100000; // "6" 
         5'b00111: DisplayFloorReg = 7'b0001111; // "7" 
         5'b01000: DisplayFloorReg = 7'b0000000; // "8"  
         5'b01001: DisplayFloorReg = 7'b0000100; // "9" 
         default: DisplayFloorReg = 7'b0000001; // "0"
         endcase
    end

     assign DisplayFloor = DisplayFloorReg;
    
endmodule