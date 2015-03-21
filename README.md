# DCS-JTACAutoLaze
Auto lazes targets in DCS

Test mission showing two JTACS who will automatically lase targets for you!

All it needs is a mission start trigger with  

InitSparkleLase('JTAC1', 1688)

JTAC1 refers to a group containing only one JTAC and the second parameter is the laser code

Multiple JTACS can be used if you want by just adding more DO Script triggers to the mission start trigger but they must all
be in different groups