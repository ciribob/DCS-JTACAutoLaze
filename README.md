#JTAC Automatic Targeting and Laser Script

Allows a JTAC to mark and hold an IR and Laser point on a target allowing TGP's to lock onto the lase and ease
of target location using NV Goggles

The JTAC will automatically switch targets when a target is destroyed or goes out of Line of Sight

The JTACs can be configured globally to target only vehicles or troops or all ground targets

**NOTE: LOS doesn't include buildings or tree's... Sorry! **

The script can also be useful in daylight by enabling the JTAC to mark enemy positions with Smoke.
The JTAC will only move the smoke to the target every 5 minutes (to stop a huge trail of smoke markers) unless the target
is destroyed, in which case the new target will be marked straight away with smoke.

You can also enable an F10 menu option for coalition units allowing the JTAC(s) to report their current status.

If a JTAC is down it won't report in.

##USAGE:

Place JTAC units on the map with the mission editor putting each JTAC in it's own group containing only itself and no
other units. Name the group something easy to remember e.g. JTAC1 and make sure the JTAC units have a unique name which must
not be the same as the group name. The editor should do this for you but be careful if you copy and paste.

Load the script at the start of the mission with a Trigger Once or as the init script of the mission

Run the code below as a DO SCRIPT at the start of the mission, or after a delay if you prefer

```lua
JTACAutoLase('JTAC1', 1688)
```

Where JTAC1 is the Group name of the JTAC Group with one and only one JTAC unit and the 1688 is the Laser code.

You can also override global settings set in the script like so:

```lua
JTACAutoLase('JTAC1', 1688, false,"all") 
```
This means no smoke marks for this JTAC and it will target all ground troops

```lua
JTACAutoLase('JTAC1', 1688, true,"vehicle")
```
This smoke marks for this JTAC and it will target ONLY ground vehicles

```lua
JTACAutoLase('JTAC1', 1688, true,"troop")
```
This means smoke marks are enabled for this JTAC and it will target ONLY ground troops

```lua
JTACAutoLase('JTAC1', 1688, true,"troop",1)
```
This means smoke marks are enabled for this JTAC and it will target ONLY ground troops AND smoke colour will be Red

```lua
JTACAutoLase('JTAC1', 1688, true,"troop",0)
```
This means smoke marks are enabled for this JTAC and it will target ONLY ground troops AND smoke colour will be Green

```lua
JTACAutoLase('JTAC1', 1688, true,"all", 4) 
```
This means no smoke marks for this JTAC and it will target all ground troops AND mark with Blue smoke

Smoke colours are: Green = 0 , Red = 1, White = 2, Orange = 3, Blue = 4

The script doesn't care if the unit isn't activated when run, as it'll automatically activate when the JTAC is activated in
the mission but there can be a delay of up to 30 seconds after activation for the JTAC to start searching for targets.

You can also run the code at any time if a JTAC is dynamically added to the map as long as you know the Group name of the JTAC.

The 3 missions demonstrate different ways of using the script with the JTACTest-troops-vehicles demonstrating the ability to individually configure each JTAC. Make sure you look in the triggers to see how.

Last Edit:  21/04/2015

Last Change: 
Added laser code to f10 status
Added new config of JTAC smoke colour globally or per JTAC
Added Target configuration and global overrides for JTAC
Added Config option for displaying target location
Added MGRS and Lat Lon Position to JTAC Status


