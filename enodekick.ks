clearScreen.
local burnTime to 21.8.
local thrust to 17.3.


set nd to nextNode.
print "Node selected..".
lock steering to lookdirup(nd:deltav*(thrust/abs(thrust)),-body:position).
print "Steering locked".
set rcs to true.
print "RCS Activated".


wait until nd:eta <= (burnTime/2) + 15.
set ship:control:roll to 1.
print "Rolling for 15 seconds".
wait until nd:eta <= burnTime/2.
stage.
print "stage".

