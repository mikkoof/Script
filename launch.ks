// *********** parameters *******************


parameter desiredApoapsis       to 200_000.
parameter desiredPeriapsis      to 200_000. //At what altitude does the craft hit 90 pitch 
parameter turnCompleteAltitude  to 140_000.
parameter upperStageBurnTime    to 120.     
parameter pitchAtAp             to 90.      //90
parameter desiredInclanation    to 0. 
parameter upperIgnitions        to 1.

clearScreen.
LOCK g TO SHIP:BODY:MU / (SHIP:BODY:RADIUS + SHIP:ALTITUDE)^2.
LOCK twr to (Thrust() / (g * ship:mass)).



// *********** start pitch control *********************

RUNONCEPATH("Library/lib_BisectionSolver.ks").
RUNONCEPATH("Library/lib_derivator.ks").

local v_accel_func to makeDerivator_N(0,10).
local v_jerk_func to makeDerivator_N(0,20).

function GetVerticalAcceleration {
    return v_accel_func:call(verticalspeed).
}

function GetVerticalJerk {
    return v_jerk_func:call(GetVerticalAcceleration).
}

function AltitudeIntegrationJerk {
    parameter inputTime.

    local x to inputTime.
    local d to altitude.
    local c to verticalSpeed.
    local b is GetVerticalAcceleration()/2.
    local a is GetVerticalJerk()/6.

    return d + c*x + b*x^2 +  a*x^3.
}

function TimeToAltitudeScore {
    parameter inputTime.
    return turnCompleteAltitude - AltitudeIntegrationJerk(inputTime). //160_000.
}

function MakePitchRateFunction {
    parameter vertspeed_min.
    local pitchDestination to 0.
    local finalPitch to pitchAtAp.
    local beginPitch to false.
    local timeLast to time:seconds.

    return {
        parameter timeToAltitude.

        if not(beginPitch) and verticalSpeed > vertspeed_min {
            set beginPitch to true.
        }

        local timeNow to time:seconds.
        local dt to timeNow - timeLast.
        set timeLast to timeNow.

        if beginPitch and (MachNumber() < 0.85 or MachNumber() > 1.1) {
            local pitchRate to max(0, (finalPitch - pitchDestination)/timeToAltitude).
            set pitchDestination to min(finalPitch, max(0,pitchDestination + dt*pitchRate)).
        }
        return pitchDestination.
    }.
}


function PitchController2 {
    parameter coast to true.
    if coast {
        SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
        if not uppers[0]:ignition {
            stage.
        }
        print "staging".
        wait 0.5.
    }
    CreateCircularisationNode().
    set line to 18.
    set nd to nextNode.

    local TIsp to ThrustIsp().
    local upperStageThrust to TIsp[0].
    local vex to TIsp[1].

    local maxAcc to upperStageThrust/mass.

    print "vex" + vex at (0,line).
    set line to line +1.
    print "max acc" + maxAcc at (0,line).
    set line to line +1.
    print "e" + constant:e at (0,line).
    set line to line +1.
    print "-nd:deltaV:mag" + -nd:deltav:mag at (0,line).


    local dob to vex / maxAcc * (1 -  constant:e^(-nd:deltav:mag/vex)).
    local dob2 to vex/maxAcc - vex*dob/nd:deltav:mag.

    set line to line +1.
    print "dob" + dob at (0,line).
    set line to line +1.
    print "dob2" + dob2 at (0,line).
    set line to line + 1.
    print "Burn duration: " + round(dob) + " s" at(0, line).
    
    lock steering to lookdirup(nd:deltav*(upperStageThrust/abs(upperStageThrust)),-body:position).
    set rcs to true.
    local initialDv to nd:deltav.
    local done to false.
    if coast {
        wait until nd:eta <= dob2 - 5.
        SortUllage().
    }
    wait until nd:eta <= dob2.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
    until done {
        set maxACc to upperStageThrust/ship:mass.
        if(vdot(initialDv, nd:deltav) < 0 and apoapsis > desiredApoapsis) {
            SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
            set done to True.
        }
    }
    remove nd.
    
    wait 0.001.
}


local timeToAltitudeSolver to makeBiSectSolver(TimeToAltitudeScore@,100,101).
local timeToAltitudeTestPoints to timeToAltitudeSolver().
local PitchController to MakePitchRateFunction(10).

// *********** end pitch control *********************



set boosters to SHIP:PARTSDUBBED("Booster").
set sustainers to SHIP:PARTSDUBBED("Sustainer").
set uppers to SHIP:PARTSDUBBED("Upper").


//Countdown
PRINT "Count down:".
FROM {local countdown is 4.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1. // pauses the script here for 1 second.
}


// ************* Init launch sequence *************
set guidanceState to 1.
set stageState to 1.

local turnAltitude         to 10.
// local lastApoapsis          to 0.
local pitchAng              to 0.
local compass               to inst_az(desiredInclanation).
lock steering               to lookdirup(heading(compass,90-pitchAng):vector,ship:facing:upvector).
set ship:control:Pilotmainthrottle to 1.
set fairingsDeployed to false.
set timeToFlameout to upperStageBurnTime.
// set upperStageIgnitedTime to 0.
set nd to 0.

Launch().

// ************ state machine **********************

until guidanceState = 0 {
    if guidanceState = 1 {
        if altitude > turnAltitude {
            set guidanceState to 2.
        }
    }
    else if guidanceState = 2 {
        set timeToAltitudeTestPoints to TimeToAltitudeSolver().
        set pitchAng to round(pitchController(timeToAltitudeTestPoints[2][0]),2).
    }

    else if guidanceState = 3 {

        wait until stage:READY.

        pitchController2().
        set guidanceState to 0.
        wait 0.001.
    }
    else if guidanceState = 3.1 {   
        wait until stage:READY.
        PitchController2(false).         
        set guidanceState to 0.
        wait 0.001.
    }
    else if guidanceState = 0 {
        set ship:control:Pilotmainthrottle to 0.
    }
    Stager().
    OpenFairings().
//Touchbase
    set line to 0.
    print "******** DEBUG ********" at(0, line).
    set line to line + 1.
    print "TWR = " + twr at(0, line).
    set line to line + 1.
    print "Guidance state = " + guidanceState at(0, line).
    set line to line + 1.
    print "Stage state = " + stageState at(0, line).
    set line to line + 1.
    print "Apoapsis = " + ship:apoapsis at(0, line).
    set line to line + 1.
    print "Pitch = " + pitchAng at(0, line).
    set line to line + 1.
    print "steering = " + steering at(0, line).
    set line to line + 1.
    print "launch upper = " + (ship:apoapsis < desiredPeriapsis or ETA:apoapsis < (upperStageBurnTime / 2)) at(0, line).
    set line to line + 1.
    print "Eta apoapsis = " + ETA:apoapsis at(0, line).
    set line to line + 1.
    print "Boosters = " + boosters:length at(0, line).
    set line to line + 1.
    print "Sustainers = " + sustainers:length at(0, line).
    set line to line + 1.
    print "Uppers = " + uppers:length at(0, line).
    local surfaceGravity to (body:mu/body:radius^2).
    local orbitalSpeed to (body:radius * SQRT(surfaceGravity/(body:radius+apoapsis))).
    local speedAtAp to SQRT(((1-ship:orbit:eccentricity) * ship:orbit:body:mu) / ((1 + ship:orbit:eccentricity) * ship:orbit:semimajoraxis)).
    set line to line + 1.
    print "SurfaceGravity= " + surfaceGravity at(0, line).
    set line to line + 1.
    print "orbitalSpeed= " + orbitalSpeed at(0, line).
    set line to line + 1.
    print "speed at ap= " + speedAtAp at(0, line).
    
}

// *********** start azimuth control *****************
function inst_az {
	parameter	inc. // target inclination

	// find orbital velocity for a circular orbit at the current altitude.
	local V_orb is max(ship:velocity:orbit:mag + 1,sqrt( body:mu / ( ship:altitude + body:radius))).

	// Use the current orbital velocity
	//local V_orb is ship:velocity:orbit:mag.

	// project desired orbit onto surface heading
	local az_orb is arcsin ( max(-1,min(1,cos(inc) / cos(ship:latitude)))).
	if (inc < 0) {
		set az_orb to 180 - az_orb.
	}

	// create desired orbit velocity vector
	local V_star is heading(az_orb, 0)*v(0, 0, V_orb).

	// find horizontal component of current orbital velocity vector
	local V_ship_h is ship:velocity:orbit - vdot(ship:velocity:orbit, up:vector:normalized)*up:vector:normalized.

	// calculate difference between desired orbital vector and current (this is the direction we go)
	local V_corr is V_star - V_ship_h.

	// project the velocity correction vector onto north and east directions
	local vel_n is vdot(V_corr, ship:north:vector).
	local vel_e is vdot(V_corr, heading(90,0):vector).

	// calculate compass heading
	local az_corr is arctan2(vel_e, vel_n).
	return az_corr.
}

// *********** end azimuth control *********************

local function Launch{
    if stage:nextDecoupler:istype("LaunchClamp") {
        stage.
        // print twr.
        if stage:nextDecoupler:istype("LaunchClamp") {
            wait until twr > 0.5.
            // print twr.
            stage.
            wait 0.5.
        }
    } 
}


function Stager {
    if stage:nextDecoupler<>"None" and stageState = 1{
        if boosters:length <> 0 {
            for booster in boosters {
                if (booster:maxthrust * 0.1) > booster:thrust
                {
                    UNTIL STAGE:READY WAIT 0.
                    stage.
                    set boosters to SHIP:PARTSDUBBED("Booster").
                    // print "Staging booster. Boosters lenght: " + boosters:length at(0, line).
                }
            }
        } 
        else if sustainers:length <> 0 {
            //set stageState to toStage.
            for sustainer in sustainers {
                if sustainer:flameout {
                    if apoapsis > desiredApoapsis {
                        SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
                    }
                    UNTIL STAGE:READY WAIT 0.
                    stage.
                    set sustainers to SHIP:PARTSDUBBED("Sustainer").
                    set rcs to true.
                }
            }
        }
        else  {
            if apoapsis > desiredPeriapsis { 
                if upperIgnitions > 1 {
                    set stageState to 2.
                    set guidanceState to 3.
                    set timeToFlameout to TIME:SECONDS + upperStageBurnTime. //seconds + 120
                }
                else {
                    set stageState to 2.
                    set guidanceState to 3.1.
                    set timeToFlameout to TIME:SECONDS + upperStageBurnTime. //seconds + 120
                }
            }
        }
    }
}

function CreateCircularisationNode {
    local surfaceGravity to (body:mu/body:radius^2).
    local orbitalSpeed to (body:radius * SQRT(surfaceGravity/(body:radius+apoapsis))).
    local speedAtAp to SQRT(((1-ship:orbit:eccentricity) * ship:orbit:body:mu) / ((1 + ship:orbit:eccentricity) * ship:orbit:semimajoraxis)).
    local dvCirc to orbitalSpeed - speedAtAp.
    local circNode to NODE (TIME:SECONDS + eta:apoapsis,0 ,0 , dvCirc).
    add circNode.
    set line to line +1.
    print "node created" at (0, line).
}

function SortUllage {
    // stage.   
    set ship:control:fore to 1.
    wait UNTIL uppers[0]:FUELSTABILITY >= 1.
    wait 0.1.
    set ship:control:fore to 0.
    set ship:control:Pilotmainthrottle to 1.
}

local function Thrust {
   Set TotalThrust to 0.
   List Engines in engs.
   For e in engs {
      set TotalThrust to TotalThrust + e:Thrust.
   }
   return TotalThrust.
}

function ThrustIsp {
    local vex to 1.
    local ff to 0.
    local tt to 0.
    for upper in uppers {
        set ff to ff + upper:availablethrust/max(upper:visp, 0.01).
        set tt to tt + upper:availablethrust*vDot(facing:vector, upper:facing:vector).
    }
    if tt<>0 set vex to 9.80665*tt/ff.
    return list(tt,vex).
}

function MachNumber {
    
    parameter idx is 1.4.
    if not body:atm:exists or body:atm:altitudepressure(altitude) = 0 {
        return 0.
    }
    return round(sqrt(2 / idx * ship:q / body:atm:altitudepressure(altitude)),3).
}

function OpenFairings {
    if (ship:altitude > 90_000 and not fairingsDeployed) {
        stage.
        set line to line +1.
        print "Staging fairings " at(0, line).
        wait 1.
        set fairingsDeployed to true.
    }
}
