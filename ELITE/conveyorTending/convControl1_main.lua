-- State Machine n#
-- 2024/08/22

-- Variable Setup -------------------------------------------------------------------------------
-- io list
-- input signals
local bufferOut="I4"  -- sensor in the buffer out gate
local workIn="I6" -- sensor in the robot working position
local otherBufferIn="I9" -- sensor in the entry of the next section bufer
-- output
local bufferStop="O0" -- locking actuater of buffer output
local workStop="O2" -- locking actuator of work position output

-- global variables
readyToWork="B001" -- internal variable seting if the work position is ready for the robot to work
robotDone="B002" -- internal variable to get if robot finished work

-- System Variables

systemOn="M550"
getReady="M549"
jobRunning="M427"

-- startup variables
--input to check
initStatus="M473"
alarmStatus="M428"
servoStatus="M400"
preciseStatus="M472"
inFrstLine="M464"
inPause="M425"

-- output to user plc
alarmClear="M551"
servoEnable="M552"
setCalibration="M553"
setMainJob="M554"
setPlay="M555"
setPause="M556"



-- Inetialization ----------------------------------------------------------------------------------
-- Script Variables
local stateValue=-1 -- value of state
local startDelay = 10 -- Delay value for the start
local lockDelay = 1 -- Delay value for the start
local stateMachNum = 1 -- number for the conveyor secttion 

set_robot_io_status (getReady,0)

while(1)do
    
    elite_print("Ready")
    stateValue=-1
    startupValue=-1
    -- Initialization of variables
    set_global_variable (readyToWork,0)
    set_global_variable (robotDone,0)
    set_robot_io_status (workStop,0)
    set_robot_io_status (bufferStop,0)
	
	set_robot_io_status (alarmClear,0)
	set_robot_io_status (servoEnable,0)
	set_robot_io_status (setCalibration,0)
	set_robot_io_status (setMainJob,0)
	set_robot_io_status (setPlay,0)
    

    -- if system on (green buton) and not pause and job is not running: do the startup sequence
    while get_robot_io_status(jobRunning)==0 and get_robot_io_status(systemOn)==1 and get_robot_io_status(inPause)==0 do
        
        -- reset alarms
        if startupValue == -1 then
			sleep (5)
			set_robot_io_status (alarmClear,1) -- M551 set S4 in user plc
            sleep (3)
			set_robot_io_status (alarmClear,0)

            if get_robot_io_status(alarmStatus)==0  then
          
				startupValue=0
            else 
                sleep (1)
            end

        -- enable servos
        elseif startupValue==0 then
			set_robot_io_status (servoEnable,1) -- M552 set S3 in user plc
            sleep (3)
			set_robot_io_status (servoEnable,0)

            if get_robot_io_status(servoStatus)==1  then
				startupValue=1
            else 
                sleep (1)
            end
        
        -- calibrate robot
        elseif startupValue==1 then
            -- use get ready variable to disable/enable conveyor movemente. If in calibration, the jobRunning variable goes "True"
            set_robot_io_status (getReady,0)
            set_robot_io_status (setCalibration,1) -- M553 set S22 in user plc
            sleep (3)
			set_robot_io_status (setCalibration,0)

            if get_robot_io_status(preciseStatus)==1 then
				sleep (5)
                set_robot_io_status (getReady,1)
				startupValue=2
            else 
                sleep (1)
            end
        -- set job to firts line. None: check if "Main Program" option is selected in the pendent
        elseif startupValue==2 then
            set_robot_io_status (setMainJob,1) -- M554 set S6 in user plc
            sleep (3)
			set_robot_io_status (setMainJob,0)

            if get_robot_io_status(inFrstLine)==1 then
                startupValue=3
            else 
			    sleep (1) 
            end
        -- set program to run
        elseif startupValue==3 then
                set_robot_io_status (setPlay,1) -- M555 set S1 in user plc
                sleep (3)
				set_robot_io_status (setPlay,0)
				
            if get_robot_io_status(jobRunning)==1 then
				startupValue=-1
            else 
                sleep (1)
            end
        else
            startupValue=-1
        end
    end
    -- if button is pressed it will pause
    if get_robot_io_status(systemOn)==0 and get_robot_io_status(jobRunning)==1 then
       set_robot_io_status(setPause,1) -- M556 set S2
       sleep (1)
       set_robot_io_status(setPause,0)
       sleep (0.5)
    end

    -- if button is pressed it will start
    if get_robot_io_status(inPause)==1 and get_robot_io_status(systemOn)==1 then
       set_robot_io_status(setPlay,1) -- M556 set S2
       sleep (1)
       set_robot_io_status(setPlay,0)
       sleep (0.5)
    end

    -- if job runing and system is on (button has been pressed to start)
    while get_robot_io_status(systemOn)==1 and get_robot_io_status(jobRunning)==1 do
        
        if stateValue==-1 then
			sleep (startDelay)
            if get_robot_io_status (workIn)==0 then 
                -- set variable for the robot to start
                set_robot_io_status (bufferStop,1)
				sleep (lockDelay)
            end
			
			
            set_robot_io_status (bufferStop,0)
			-- set next case
			stateValue=0

        elseif stateValue==0 then
			-- if cart has not arrived to the work location way more time
            if (get_robot_io_status (workIn)==0) then
				sleep (startDelay)
			end
			
            if get_robot_io_status (workIn)==0 then
                stateValue=-1 
            else
                stateValue=1 
            end



        elseif stateValue==1 then
			

            -- if work area has part
            if get_robot_io_status (workIn)==1 then 
                -- set variable for the robot to start
                set_global_variable (readyToWork,1)
            end

            -- if robot as finished the pick
            if get_global_variable (robotDone)==1 then
                -- go to new case
                stateValue=2
            end

        elseif stateValue==2 then
            
            -- reinitializa robotdone variable
            set_global_variable (robotDone,0)
			
            -- if work area has part
            if ((get_robot_io_status (workIn)==1) ) then
                -- if the next section bufer is not full
                if  (get_robot_io_status (otherBufferIn) == 0) then
                    -- open the work position locker
                    set_robot_io_status (workStop,1)
                    -- initializa the ready to work variable
                    set_global_variable (readyToWork,0)
                    stateValue=3
                end
            end
        elseif stateValue==3 then


            -- if the is no  part in the work position
            if get_robot_io_status (workIn)==0 then
                -- close the locker
				sleep (lockDelay)
                set_robot_io_status (workStop,0)
                -- set new state
                stateValue=4
            end
            
        elseif stateValue==4 then

            -- if there is a part in the buffer
            if get_robot_io_status (bufferOut)==1 then
                -- open bufer locker
                set_robot_io_status (bufferStop,1)
                --set new state
                stateValue=5
            end


        elseif stateValue==5 then

            -- if there is no part in the bufer
            if get_robot_io_status (bufferOut)==0 then
                -- close the buffer
				sleep (lockDelay)
                set_robot_io_status (bufferStop,0)
                -- go back to initial state
                stateValue=1
            end
        else
            -- unknown state reached
            elite_print("Read error")
            stateValue=-1
        
        end

        sleep (0.1) 
    end
    -- clocking delay
    sleep (1)  

end