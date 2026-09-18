# **WELCOME TO THE UAS Aerodynamics / Airframe Team Git Page for Section 13 of Fall 2026 Senior Design!**

#### Team Lead: Andrew Naiberg
#### Team Members: Adarsh Boddeda, Harvey Watson, Lucas Brooks

__For questions on the layout of the Git, reach out to Adarsh.__

### Key Objectives and Reminders
- All decisions should be tied to the original requirements.
- Documentation is paramount, so please continue to put comments on any Git commits and notes through these .md files.
- Be communicative with leadership and other subteams.

### Summary of Key Requirements
- Volumetric limits: 50 cm x 50 cm x 30 cm
- Total Mass: 25 lb max (11.3 kg)
- Endurance: 15 min operation
- Speed/Velocity: 0.5 m/s operational limit. Design for up to 2 m/s
- Altitude: Up to 2 m above ground in Boulder
- Temperature: Operate in temperatures ranging from 19 F to 95 F
- Battery: Support removable battery system
- Thermals: Effectively manage heat for the avionics (define later)
- KO Zone: Provide a keep out zone for flight hardware and avionics
- Aperture: Include an aperture for the camera

### Trade Studies (as of 9/16/26)
- The following is the break down of who is responsible for each of the trade studies currently.

#### Adarsh
- Developing the current dynamics MATLAB model to simulate stability in hover/glide based on different geometries.
  -  Testing chassis geometry/sizing, CG balance (location of avionics/battery/etc.), arm length, material choices.
- Developing thermal simulation model to estimate if we should be concerned about heat build up during the 15 minutes of operation.
  -  If heat build up is a problem, compare the solutions of venting or hollow cage.

#### Andrew
- Working on CAD / mass model for airframe.

#### Harvey
- Wrote documentation for estimations of force and moments experienced by the drone in a worst-case-scenario crash event.
  - Estimations for shear force and moment values given by estimations from the propulsion team.
- Created a MATLAB structural simulation to determine bending deflection as a function of mass, diameter, length, and cross-sectional shape of a material optimizing for high strength to weight ratio.
  - Trade Studied materials include:
    - Carbon Fibre
    - Aluminium 6061
    - Fiberglass
    - Carbon Fibre Reinforced Nylon (PA6-CF, 3D Printable)
    - Titanium Alloy Ti-6Al-4V (6% Aluminium 4% Vanadium)

#### Lucas
- Working on CAD / mass model for airframe.
  
