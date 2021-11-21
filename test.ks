LOCK g TO SHIP:BODY:MU / (SHIP:BODY:RADIUS + SHIP:ALTITUDE)^2.
LOCK twr to (Thrust() / (g * ship:mass)).
set virtualOrbit to createOrbit(V(300_000, 0 ,0), V(0, 0, 300_000 + Earth:radius), Earth, 0).
print virtualOrbit.
// print virtualOrbit:apoapsis.

// local function Thrust {
//    Set TotalThrust to 0.
//    List Engines in engs.
//    For e in engs {
//       set TotalThrust to TotalThrust + e:Thrust.
//    }
//    return TotalThrust.
// }