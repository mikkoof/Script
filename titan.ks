parameter desiredApoapsis         to 200_000.
parameter desiredPeriapsis        to 160_000.
parameter desiredInclanation      to 0. 
parameter turnCompleteAltitude    to 140_000.
parameter upperStageBurnTime      to 240.5.     
parameter pitchAtAp               to 90.      


runpath("launch.ks", desiredApoapsis, desiredPeriapsis, turnCompleteAltitude, upperStageBurnTime, pitchAtAp, desiredInclanation).