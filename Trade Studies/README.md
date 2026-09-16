# READ ME FOR INFO ACROSS THE BOARD IN TRADE STUDIES SCRIPTS

### About the Excel Sheet:
- File will be used to iteratively compare designs. 
- Any configurations that need to be tested gets a row to itself. 
- Distance units are entered in **CENTIMETERS** and are then converted to **METERS** in the MATLAB script AircraftGeometry.m
- Mass units are entered in **KILOGRAMS** and stay that way for the final script.
- Comments are placed on the headers to provide a bit more context.

### Script Notes:

Comments:
- Right now, initial configuration isn't stable in hover for one reason or another. I (Adarsh) will spend time over the next day or so refining the model to make sure there isn't a problem in the code, then we will refine the actual configuration.
#### AircraftGeometry.m
- Configurations are currently fixed at hollow cube.
- Will add implementation for octagonal prism, egg shape, and cube shell
- Assume arms to be hollow cylinders.
- Look for monocoque shape (shell handles all loads with no chassis beams)
- Assume center of propellers are attached at the end of the arms.

#### AerodynamicsModel.m
- Currently using Newton's Model for Bluff Bodies for the cube. assumption will break for a more streamlined body.
- Planform area / projected area model will need to be adjusted for different shapes.

