clearScreen.


set ship:control:Pilotmainthrottle to 1.
set steer to heading(90,90).
lock steering to steer.
LOCK g TO SHIP:BODY:MU / (SHIP:BODY:RADIUS + SHIP:ALTITUDE)^2.
LOCK twr to (Thrust() / (g * ship:mass)).

set boosters to SHIP:PARTSDUBBED("Booster").
set sustainers to SHIP:PARTSDUBBED("Sustainer").


PRINT "Count down:".
FROM {local countdown is 4.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1. // pauses the script here for 1 second.
}
Launch().

set state to 1.
print "set mode to 1".


until state = 0 {
    set state to stateControl().
    Stager().
    set steer to Controller().
    if state = 0 {
        set ship:control:Pilotmainthrottle to 0.
    }
}


//State machine
//1 accelerate to 50 and adjust direction.
//2 gravity turn
//3 fly out of atm
//4 steer to space.

function StateControl {
    if state = 1 {
        if altitude >= twr*100 {
            return 2.
        }
        else return 1.
    }

    else if state = 2 {
        if SHIP:VELOCITY:SURFACE:MAG >= twr * 80 {
            return 3.
        }
        else 
        return 2.
    }

    else if state = 3 {
        if altitude > 55_000 {
            return 4.
        } 
        else return 3.
    }

    else if state = 4 {
        if ship:apoapsis > 200_000 return 0.
    }
}

function Controller {

    if state = 1 {
        return heading(90,90).
    }
    else if state = 2 {
        return heading(90,82).
    }
    else if state = 3 {
        return heading(90, 90 - 5 * twr).
    }
    else if state = 4 {
        return velocity:surface.
    }
    else if state = 5 {
        return heading(90, 45).
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
