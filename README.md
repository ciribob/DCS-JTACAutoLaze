# DCS-JTACAutoLase
Auto lases targets in DCS

Test mission showing two JTACS who will automatically lase targets for you.

All it needs is a mission start trigger with the code below as a DO SCRIPT 

JTACAutoLase('JTAC1', 1688)

JTAC1 refers to a group containing only one JTAC and the second parameter is the laser code

Multiple JTACS can be used if you want by just adding more DO Script triggers to the mission start trigger but all JTACS must
be in different groups of one vehicle

If a JTAC has a late start, you can either run the script at the start of the mission, or when the unit is activated.

The 3 test missions are what I used to test the script and also show how to set it all up.

To add the sound file, either add it as a sound to play at the start of the mission with a trigger or manually 
add it to the mission by renaming the mission.zip, dragging it in, then renaming back to .miz