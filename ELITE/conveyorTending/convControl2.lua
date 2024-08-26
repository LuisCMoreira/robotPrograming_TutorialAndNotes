-- State Machine n#
-- 2024/08/22

-- Variable Setup -------------------------------------------------------------------------------
-- io list
-- input signals
local bufferOut="I7"  -- sensor in the buffer out gate
local workIn="I5" -- sensor in the robot working position
local otherBufferIn="I8" -- sensor in the entry of the next section bufer
-- output
local bufferStop="O3" -- locking actuater of buffer output
local workStop="O1" -- locking actuator of work position output

-- second robot setup
-- global variables
readyToWork="O5" -- inout to set if the work position is ready for the robot to work
robotDone="I13" -- input to get if robot finished work

hasRobot ="B000" -- if this variable is on, there is a second robot

-- Inetialization ----------------------------------------------------------------------------------
-- Script Variables
local stateValue=0 -- value of state
local startDelay = 5 -- Delay value for the start
local lockDelay = 1 -- Delay value for the start
local stateMachNum = 2 -- number for the conveyor secttion 



while(1)do
    
    -- elite_print("Ready")
    stateValue=0
    -- Initialization of variables
    set_global_variable (readyToWork,0)
    set_global_variable (robotDone,0)
    set_robot_io_status (workStop,0)
    set_robot_io_status (bufferStop,0)

    while get_robot_io_status("M550")==1 and get_robot_io_status("M417")==1 do
        -- elite_print("Running")
        if stateValue==-1 then
            --elite_print("in State ", stateValue," on section: ", stateMachNum)

            sleep (startDelay)

            if get_robot_io_status (workIn)==0 then 
                -- set variable for the robot to start
                set_robot_io_status (bufferStop,1)
				sleep (lockDelay)
            end
			
            -- wait x seconds
            
            set_robot_io_status (bufferStop,0)
			-- set next case
			stateValue=0

        elseif stateValue==0 then
            sleep (startDelay)
            if get_robot_io_status (workIn)==0 then
                stateValue=-1 
            else
                stateValue=1 
            end


        elseif stateValue==1 then
            --elite_print("in State ", stateValue," on section: ", stateMachNum)
            
            -- if work area has part
            if get_robot_io_status (workIn)==1 then 
                -- set variable for the robot to start
                set_robot_io_status (readyToWork,1)
            end

            -- if robot as finished the pick
            if get_robot_io_status (robotDone)==1 or (get_global_variable (hasRobot)==0 and (get_robot_io_status (workIn)==1) ) then
                -- go to new case
                stateValue=2
            end

        elseif stateValue==2 then
            --elite_print("in State ", stateValue," on section: ", stateMachNum)
            
            -- reinitializa robotdone variable
            set_robot_io_status (robotDone,0)
			
            -- if work area has part
            if ((get_robot_io_status (workIn)==1) ) then
                -- if the next section bufer is not full
                if  (get_robot_io_status (otherBufferIn) == 0) then
                    -- open the work position locker
                    set_robot_io_status (workStop,1)
                    -- initializa the ready to work variable
                    set_robot_io_status (readyToWork,0)
                    stateValue=3
                end
            end

        elseif stateValue==3 then 
            --elite_print("in State ", stateValue," on section: ", stateMachNum)
			

            -- if the is no  part in the work position
            if get_robot_io_status (workIn)==0 then
                -- close the locker
                sleep (lockDelay)
                set_robot_io_status (workStop,0)
                -- set new state
                stateValue=4
            end
            
        elseif stateValue==4 then 
            --elite_print("in State ", stateValue," on section: ", stateMachNum)

            -- if there is a part in the buffer
            if get_robot_io_status (bufferOut)==1 then
                -- open bufer locker
                set_robot_io_status (bufferStop,1)

                --set new state
                stateValue=5
            end
			
            --if get_robot_io_status (bufferOut)==0 then
                -- close the buffer
            --    sleep (lockDelay)
             --   set_robot_io_status (bufferStop,0)
                -- go back to initial state
               -- stateValue=1
            --end


        elseif stateValue==5 then
            --elite_print("in State ", stateValue," on section: ", stateMachNum)
            -- if there is no part in the bufer
            if get_robot_io_status (bufferOut)==0 then
            --    -- close the buffer
				sleep (lockDelay)
                set_robot_io_status (bufferStop,0)
            --    -- go back to initial state
				stateValue=1
            end
			
			--stateValue=1

        else
            --- unknown state reached
            elite_print("Read error")
            stateValue=-1
       
        end

        sleep (0.1) 
    end
    -- clocking delay
    sleep (1)  

end