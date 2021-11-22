set desiredPeriapsis    to 180_000.
set upperStageBurnTime  to 120.     
set pitchAtAp           to 90.      
set desiredInclanation  to 99. 
set upperStageThrust    to 33.8.   

runpath("launch.ks", desiredPeriapsis, upperStageBurnTime, pitchAtAp, desiredInclanation, upperStageThrust).