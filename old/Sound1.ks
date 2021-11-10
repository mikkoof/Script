clearScreen.

set ship:control:Pilotmainthrottle to 1.

LOCK g TO SHIP:BODY:MU / (SHIP:BODY:RADIUS + SHIP:ALTITUDE)^2.
LOCK twr to (Thrust() / (g * ship:mass)).

set boosters to SHIP:PARTSDUBBED("Booster").
set sustainers to SHIP:PARTSDUBBED("Sustainer").


PRINT "Count down:".
FROM {local countdown is 4.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1. // pauses the script here for 1 second.
}

set state to 1.
print "set mode to 1".
Launch().
until state = 0 {
    Stager().
    if state = 0 {
        set ship:control:Pilotmainthrottle to 0.
    }
}

function Stager {
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

local function Thrust {
   Set TotalThrust to 0.
   List Engines in engs.
   For e in engs {
      set TotalThrust to TotalThrust + e:Thrust.
   }
   return TotalThrust.
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