JTAC Automatic Targeting and Laser Script

Allows a JTAC to mark and hold an IR and Laser point on a target allowing TGP's to lock onto the lase and ease
of target location using NV Goggles

The JTAC will automatically switch targets when a target is destroyed or goes out of Line of Sight

NOTE: LOS doesn't include buildings or tree's... Sorry!

The script can also be useful in daylight by enabling the JTAC to mark enemy positions with Smoke.
The JTAC will only move the smoke to the target every 5 minutes (to stop a huge trail of smoke markers) unless the target
is destroyed, in which case the new target will be marked straight away with smoke.

You can also enable an F10 menu option for coalition units allowing the JTAC(s) to report their current status.

If a JTAC is down it won't report in.

USAGE:

Place JTAC units on the map with the mission editor putting each JTAC in it's own group containing only itself and no
other units. Name the group something easy to remember e.g. JTAC1 and make sure the JTAC units have a unique name which must
not be the same as the group name. The editor should do this for you but be careful if you copy and paste.

Load the script at the start of the mission with a Trigger Once or as the init script of the mission

Run the code below as a DO SCRIPT at the start of the mission, or after a delay if you prefer

JTACAutoLase('JTAC1', 1688)

Where JTAC1 is the Group name of the JTAC Group with one and only one JTAC unit.

The script doesn't care if the unit isn't activated when run, as it'll automatically activate when the JTAC is activated in
the mission but there can be a delay of up to 30 seconds after activation for the JTAC to start searching for targets.

You can also run the code at any time if a JTAC is dynamically added to the map as long as you know the Group name of the JTAC.

Last Edit:  26/03/2015

Change log:     Fixed JTAC lasing through terrain.
				Fixed Lase staying on when JTAC Dies
				Fixed Lase staying on when target dies and there are no other targets
				Added Radio noise when message is shown
				Stop multiple JTACS targeting the same target

