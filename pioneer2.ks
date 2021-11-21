set desiredPeriapsis      to 175_000.
set upperStageBurnTime    to 120.     
set pitchAtAp             to 90.      
set desiredInclanation    to 90. 

runpath("launch.ks", desiredPeriapsis, upperStageBurnTime, pitchAtAp, desiredInclanation).