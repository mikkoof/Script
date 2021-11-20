clearScreen.
parameter toStage to 1.
LOCK g TO SHIP:BODY:MU / (SHIP:BODY:RADIUS + SHIP:ALTITUDE)^2.
LOCK twr to (Thrust() / (g * ship:mass)).
// *********** parameters *******************
//Rocket types
// #0 Sounding Rocket
// #1 Controlled downrange rocket
// #2 Orbit with kickback

parameter rocketType            to 0.
parameter turnVelocity          to 0.   //How fast before rocket turns
parameter targetPitch           to 0.
parameter desiredInclanation    to 0. 
parameter desiredPeriapsis     to 150_000.

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
    return ship:body:atm:height - AltitudeIntegrationJerk(inputTime).
}

function MakePitchRateFunction {
    parameter vertspeed_min.
    local pitchDestination to targetPitch.
    local finalPitch to 90.
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


local timeToAltitudeSolver to makeBiSectSolver(TimeToAltitudeScore@,100,101).
local timeToAltitudeTestPoints to timeToAltitudeSolver().
local PitchController to MakePitchRateFunction(10).

// *********** end pitch control *********************



set boosters to SHIP:PARTSDUBBED("Booster").
set sustainers to SHIP:PARTSDUBBED("Sustainer").

//Countdown
PRINT "Count down:".
FROM {local countdown is 4.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1. // pauses the script here for 1 second.
}


// ************* Init launch sequence *************
set guidanceState to 1.
set stageState to 1.
local pitchAng              to 0.  
local compass               to inst_az(desiredInclanation).
lock steering               to lookdirup(heading(compass,90-pitchAng):vector,ship:facing:upvector).
set ship:control:Pilotmainthrottle to 1.

Launch().

// ************ state machine **********************

until guidanceState = 0 {
    if guidanceState = 1 {
        if SHIP:VELOCITY:SURFACE:MAG > turnVelocity {
            set guidanceState to 2.
        }
    }
    else if guidanceState = 2 {
        if rocketType > 0. {
            set timeToAltitudeTestPoints to TimeToAltitudeSolver().
            set pitchAng to pitchController(timeToAltitudeTestPoints[2][0]).
        }
    }

    else if guidanceState = 3 {
        
    }

    else if guidanceState = 0 {
        set ship:control:Pilotmainthrottle to 0.
    }
    Stager().

//Touchbase
    local line is 0.
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
    // set line to line + 1.
    // print "timeToAltitudeTestPoints = " + timeToAltitudeTestPoints at(0, line).
    
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
            wait until twr > 1.3.
            // print twr.
            stage.
        }
    } 
}

function Stager {
    if stageState = 1 {
        if stage:nextDecoupler<>"None" {
            if boosters:length <> 0 {
                for booster in boosters {
                    if booster:flameout
                    {
                        UNTIL STAGE:READY {
                            WAIT 0.
                        }
                        print "Staging booster. Boosters lenght: " + boosters:length.
                        stage.
                        set boosters to SHIP:PARTSDUBBED("Booster").
                        wait 0.
                    }
                }
            } 
            else if sustainers:length <> 0 {
                set stageState to toStage.
                for sustainer in sustainers {
                    UNTIL STAGE:READY {
                        WAIT 0.
                    }
                    if sustainer:flameout {
                        print "staging sustainer. Sustainers lenght " + Sustainers:length.
                        stage.
                        set boosters to SHIP:PARTSDUBBED("Sustainer").
                    }
                }
            }
        }
    }
}

local function Thrust {
   Set TotalThrust to 0.
   List Engines in engs.
   For e in engs {
      set TotalThrust to TotalThrust + e:Thrust.
   }
   return TotalThrust.
}

function MachNumber {
    parameter idx is 1.4.
    if not body:atm:exists or body:atm:altitudepressure(altitude) = 0 {
        return 0.
    }
    return round(sqrt(2 / idx * ship:q / body:atm:altitudepressure(altitude)),3).
}


