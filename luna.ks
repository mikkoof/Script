set desiredPeriapsis    to 140_000.
set upperStageBurnTime  to 155.     
set pitchAtAp           to 90.      
set desiredInclanation  to -28.5. 

runpath("launch.ks", desiredPeriapsis, upperStageBurnTime, pitchAtAp, desiredInclanation).