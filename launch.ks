clearScreen.

parameter toStage to 0.
//Initialize ##

LOCK g TO SHIP:BODY:MU / (SHIP:BODY:RADIUS + SHIP:ALTITUDE)^2.
LOCK twr to (Thrust() / (g * ship:mass)).

set boosters to SHIP:PARTSDUBBED("Booster").
set sustainers to SHIP:PARTSDUBBED("Sustainer").

//Countdown
PRINT "Count down:".
FROM {local countdown is 4.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1. // pauses the script here for 1 second.
}



//State Machine
//#1 Get to initial velocity
//#2 Pitch over for gravity turn to finish at 45 degrees at flameout
//#3 Keep at prograde
set guidanceState to 1.
set stageState to 1.

local pitchOverVelocity to 80.
local pitchOverAngle to 15.
local pitchAng to 90.

lock steering to heading(90, pitchAng).
set ship:control:Pilotmainthrottle to 1.

Launch().

until guidanceState = 0 {
    if guidanceState = 1 {
        set pitchAng to 90.
        if SHIP:VELOCITY:SURFACE:MAG > pitchOverVelocity {
            set guidanceState to 2.
        }
    }
    else if guidanceState = 2 {
        set angle to VANG(srfprograde:vector,steering:vector).
        if angle <= 0.5 {
            set guidanceState to 3.
        }
    }
    else if guidanceState = 3 {
        
    }

    else if guidanceState = 0 {
        set ship:control:Pilotmainthrottle to 0.
    }
    Stager().
    set pitchAng to GuidanceProgram(pitchOverAngle).

//Touchbase
    local line is 0.
    print "TWR = " + twr at(0, line).
    set line to line + 1.
    print "Pitch = " + pitchAng at(0, line).
    set line to line + 1.
    print "Guidance state = " + guidanceState at(0, line).
    set line to line + 1.
    print "Stage state = " + stageState at(0, line).
    set line to line + 1.
    print "Apoapsis = " + ship:apoapsis at(0, line).
}

function GuidanceProgram {
    parameter pitchOverAngle is 0.
    local pitchAng to 90.
    if guidanceState = 2 {
        set pitchAng to 90 - pitchOverAngle.
    }
    else if guidanceState = 3 {
        // print "test." at(0, 3).
        set pitchAng to 90 - VANG(UP:vector,srfprograde:vector).
        
    }
    return pitchAng.
}


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

