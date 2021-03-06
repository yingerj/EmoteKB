/////////////////////////////////////////////////////////////////////////////
// This program is free software: you can redistribute it and/or modify    //
// it under the terms of the GNU General Public License as published by    //
// the Free Software Foundation, either version 3 of the License, or       //
// (at your option) any later version.                                     //
//                                                                         //
// This program is distributed in the hope that it will be useful,         //
// but WITHOUT ANY WARRANTY; without even the implied warranty of          //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           //
// GNU General Public License for more details.                            //
//                                                                         //
// You should have received a copy of the GNU General Public License       //
// along with this program.  If not, see <https://www.gnu.org/licenses/>   //
/////////////////////////////////////////////////////////////////////////////


/////////////////////////////////
// Parameters                  //
/////////////////////////////////

// Unify settings of $fn parameter
FN = 16;

// TINY Value for fudging stuff
TINY = 0.1;

// Socket Edge Corner Size
SKTCNR = 0.6; // Use a big SKTCNR value to debug

//// Grid Specification: Per Column
// RXYZTJ -> {r: radius, x: finger "down", y: finger "in/out", z: up/down, t: tilt}
IDX_R = 0; IDX_X = 1; IDX_Y = 2; IDX_Z = 3; IDX_T = 4;

// Finger Pad
FINGER_I = 5; // Columns
FINGER_J = 3; // Rows
FINGER_RXYZTJ = [
  //[   r   ,   x      ,   y   ,   z   ,   t   ],
    [  40   , 9.5*9+1.0,  -4   ,   2   ,   8   ],
    [  42   , 9.5*7+0.4,  -2   ,   0   ,   2   ],
    [  42   , 9.5*5    ,   0   ,  -2   ,  -2   ],
    [  37   , 9.5*3    ,  -5   ,   3   ,  -5   ],
    [  30   , 9.5*1-0.4,  -9   ,   8   ,  -8   ]
];
// Finger Pad
THUMB_I = 2; // Columns
THUMB_J = 2; // Rows
THUMB_RXYZTJ = [
  //[   r   ,   x   ,   y   ,   z   ,   t    ],
    [  22   ,  10.2 ,   0   ,   4   ,   12   ],
    [  22   , -10.2 ,   0   ,   4   ,  -12   ]
];


/////////////////////////////////
// Utility                     //
/////////////////////////////////

module extrude(h)
    if (h > 0.0)
        linear_extrude(h)
            children();
    else
        translate([0, 0, h])
            linear_extrude(abs(h))
                children();


/////////////////////////////////
// Choc v1 Switch & Cap        //
/////////////////////////////////

module pin_nub(d, h, t=[0,0])
    translate([t[0], t[1], 0])
        extrude(h)
            circle(d/2, $fn=FN);

// choc v2 constants
base_depth = 2.2;
nub_depth = base_depth + 2.65;
pin_depth = base_depth + 3;

module choc(subtractor=false)
    union() {
        // base top
        extrude(0.8) square(15, true);
        hull() {
            translate([0,0,0.8])
                extrude(TINY)
                    square(15-2*0.6, true); // guestimate dimentions this line
            translate([0,0,5.8-3])
                extrude(TINY)
                    square(15-3.5*0.8, true); // guestimate dimentions this line
        }

        // base bottom
        extrude(-2.2)
            square(13.8, true);
        translate([0,0,-2.2])
            extrude(2.2-1.3)
                square([14.5, 13.8], true);

        // main nub
        pin_nub(3.4, -nub_depth - (subtractor ? 1 : 0));

        // r/l nubs
        pin_nub(1.9, -nub_depth - (subtractor ? 1 : 0), [-5.5, 0]);
        pin_nub(1.9, -nub_depth - (subtractor ? 1 : 0), [ 5.5, 0]);

        if (subtractor) {
        // pin rebates
            hull() {
                rebate_d = pin_depth + 1;
                translate([0, 5.9, -rebate_d])
                    cylinder(h = rebate_d, r = 2, $fn=FN);
                translate([5, 3.8, -rebate_d])
                    cylinder(h = rebate_d, r = 2, $fn=FN);
            }
        } else {
            // pins
            pin_nub(1, -pin_depth, [0, 5.9]);
            pin_nub(1, -pin_depth, [5, 3.8]);
        }
    }

module choc_cap()
    translate([0, 0, 5.8]) union() {
        extrude(2.05) square([17.5, 16.5], true);
        difference() {
            extrude(-1.5) square([17.5, 16.5], true);
            extrude(-1.5) square([17.5-2, 16.5-2], true);
        }
    }


/////////////////////////////////
// KB Submodules               //
/////////////////////////////////

socket_w = 18.0;

module socket()
    translate([0, 0, -nub_depth])
        extrude(nub_depth) square(socket_w, true);

// Corners! On the xy plane..
//
//  (-1, 1) -----( 1, 1) 
//     |            |
//  (-1,-1) -----( 1,-1) 
//
module socket_corner(c=[1,1]) {
    off = socket_w/2 - SKTCNR/2;
    translate([c[0]*off, c[1]*off, -nub_depth])
        linear_extrude(nub_depth)
            square(SKTCNR, true);
}

module socket_corner_help(rxyztj, J, i ,j)
    translate([-2,0,0]) grid(rxyztj, J, i, j) {
        color([1.0, 0.0, 0.0, 1.0]) socket_corner([ 1, 1]);
        color([0.0, 1.0, 0.0, 1.0]) socket_corner([ 1,-1]);
        color([0.0, 0.0, 1.0, 1.0]) socket_corner([-1, 1]);
        color([0.5, 0.5, 0.5, 1.0]) socket_corner([-1,-1]);
    }

// Edges! On the xy plane..
//
//     *---( 0, 1)---*
//     |             |
//  (-1, 0)       ( 1, 0)
//     |             |
//     *---( 0,-1)---*
//
module socket_edge(e=[0,1]) {
    assert(abs(e[0]) + abs(e[1]) == 1, "socket_edge parameter e is invalid");
    hull() {
        socket_corner([abs(e[0]) ? e[0] :  1, abs(e[1]) ? e[1] :  1]);
        socket_corner([abs(e[0]) ? e[0] : -1, abs(e[1]) ? e[1] : -1]);
    }
}


/////////////////////////////////
// KB Organization             //
/////////////////////////////////

module sink_hull(sink_xyz)
    hull() {
        children();
        translate(sink_xyz) children();
    }

module grid(rxyztj, J, i, j)
    // Row i-th spot
    translate ([-rxyztj[i][IDX_X], rxyztj[i][IDX_Y], rxyztj[i][IDX_Z]])
        rotate ([0, rxyztj[i][IDX_T], 0]) {
        //rotate ([0, 0, 0]) {
            // Column j-th spot
            r = rxyztj[i][IDX_R];
            a = 2*asin(9/r);
            a0 = -a*(J-1)/2;
            // Reference to center key/key-divide for odd/even respectively
            translate([0, 0, r])
                // Spot on the column arc
                rotate(-(j*a + a0), [1,0,0])
                    translate([0, 0, -(r+5.8)])
                        children();
        }

module grid_full(rxyztj, J, subtractor=false, sink_xyz=[0,0,0])
    for (i = [0:len(rxyztj)-1])
        for (j = [0:J-1]) {
            r = j==0 ? [0,0,180] : [0,0,0];
            if (subtractor) {
                sink_hull(sink_xyz) grid(rxyztj, J, i, j) children();
            } else {
                grid(rxyztj, J, i, j) rotate(r) children();
            }
        }


/////////////////////////////////
// Assembly                    //
/////////////////////////////////


// Webs go between sockets! Edges are within the same socket!
module web(rxyztj, J, i, j, adv_i, adv_j) {
    hull () {
        grid(rxyztj, J, i      , j+adv_j) socket_corner([ 1,  1]);
        grid(rxyztj, J, i      , j      ) socket_corner([ 1, -1]);
        grid(rxyztj, J, i+adv_i, j+adv_j) socket_corner([-1,  1]);
        grid(rxyztj, J, i+adv_i, j      ) socket_corner([-1, -1]);
    }
}

module pad(rxyztj, I, J)
    union() {
        // Sockets
        grid_full(rxyztj, J)
            socket();
        // Horizontal Web
        for (i = [0:I-2])
            for (j = [0:J-1])
                web(rxyztj, J, i, j, 1, 0);
        // Vertical Web
        for (i = [0:I-1])
            for (j = [0:J-2])
                web(rxyztj, J, i, j, 0, 1);
        // Center Web
        for (i = [0:I-2])
            for (j = [0:J-2])
                web(rxyztj, J, i, j, 1, 1);
    }

module pad_subtractor(rxyztj, I, J, sink_xyz)
    union() {
        // Sockets
        grid_full(rxyztj, J, true, sink_xyz) socket();
        // Horizontal Web
        for (i = [0:I-2])
            for (j = [0:J-1])
                sink_hull(sink_xyz) web(rxyztj, J, i, j, 1, 0);
        // Vertical Web
        for (i = [0:I-1])
            for (j = [0:J-2])
                sink_hull(sink_xyz) web(rxyztj, J, i, j, 0, 1);
        // Center Web
        for (i = [0:I-2])
            for (j = [0:J-2])
                sink_hull(sink_xyz) web(rxyztj, J, i, j, 1, 1);
    }

module pad_edge(rxyztj, I, J, sink_xyz)
    union() {
        // Left/Right Sides
        for (j = [0:J-1]) {
            sink_hull(sink_xyz) {
                grid(rxyztj, J, I-1, j) socket_corner([ 1,  1]);
                grid(rxyztj, J, I-1, j) socket_corner([ 1, -1]);
            }
            sink_hull(sink_xyz) {
                grid(rxyztj, J, 0, j) socket_corner([-1,  1]);
                grid(rxyztj, J, 0, j) socket_corner([-1, -1]);
            }
        }
        for (j = [0:J-2]) {
            sink_hull(sink_xyz) {
                grid(rxyztj, J, I-1, j+1) socket_corner([ 1,  1]);
                grid(rxyztj, J, I-1, j  ) socket_corner([ 1, -1]);
            }
            sink_hull(sink_xyz) {
                grid(rxyztj, J, 0, j+1) socket_corner([-1,  1]);
                grid(rxyztj, J, 0, j  ) socket_corner([-1, -1]);
            }
        }
        // Top/Bottom Sides
        for (i = [0:I-1]) {
            sink_hull(sink_xyz) {
                grid(rxyztj, J, i, J-1) socket_corner([-1, -1]);
                grid(rxyztj, J, i, J-1) socket_corner([ 1, -1]);
            }
            sink_hull(sink_xyz) {
                grid(rxyztj, J, i, 0) socket_corner([-1,  1]);
                grid(rxyztj, J, i, 0) socket_corner([ 1,  1]);
            }
        }
        for (i = [0:I-2]) {
            sink_hull(sink_xyz) {
                grid(rxyztj, J, i+1, J-1) socket_corner([-1, -1]);
                grid(rxyztj, J, i, J-1  ) socket_corner([ 1, -1]);
            }
            sink_hull(sink_xyz) {
                grid(rxyztj, J, i+1, 0) socket_corner([-1,  1]);
                grid(rxyztj, J, i,   0) socket_corner([ 1,  1]);
            }
        }
    }


module finger_pad_position() translate([0, 0, 2]) rotate([0, 26, 0]) children();

module thumb_pad_position() translate([-76, -49, 21]) rotate([35, -60, 40]) children();

module cap_n_key() {
    //color([0.6, 0.8, 0.1, 1.0]) choc();
    color([0.8, 0.4, 0.0, 1.0]) choc_cap();
    color([0.6, 0.3, 0.0, 1.0]) translate([0, 0, -3]) choc_cap(); // keycap pressed
}
module caps_n_keys() {
    finger_pad_position() grid_full(FINGER_RXYZTJ, FINGER_J) cap_n_key();
    thumb_pad_position() grid_full(THUMB_RXYZTJ, THUMB_J) cap_n_key();
}


/////////////////////////////////
// Final Assembly              //
/////////////////////////////////

//caps_n_keys();

finger_sink = [20,0,-100];
thumb_sink = [-20,0,-100];

module main_structure_hull()
    union() {
        finger_pad_position() pad(FINGER_RXYZTJ, FINGER_I, FINGER_J);
        finger_pad_position() pad_subtractor(FINGER_RXYZTJ, FINGER_I, FINGER_J, finger_sink);
        finger_pad_position() pad_edge(FINGER_RXYZTJ, FINGER_I, FINGER_J, finger_sink);

        thumb_pad_position() pad(THUMB_RXYZTJ, THUMB_I, THUMB_J);
        thumb_pad_position() pad_subtractor(THUMB_RXYZTJ, THUMB_I, THUMB_J, thumb_sink);
        thumb_pad_position() pad_edge(THUMB_RXYZTJ, THUMB_I, THUMB_J, thumb_sink);
    }

module main_structure()
    difference() {
        main_structure_hull();
        difference() {
            thumb_pad_position() pad_subtractor(THUMB_RXYZTJ, THUMB_I, THUMB_J, thumb_sink);
            thumb_pad_position() pad_edge(THUMB_RXYZTJ, THUMB_I, THUMB_J, thumb_sink);
            thumb_pad_position() pad(THUMB_RXYZTJ, THUMB_I, THUMB_J);
        }
        difference() {
            finger_pad_position() pad_subtractor(FINGER_RXYZTJ, FINGER_I, FINGER_J, finger_sink);
            finger_pad_position() pad_edge(FINGER_RXYZTJ, FINGER_I, FINGER_J, finger_sink);
            finger_pad_position() pad(FINGER_RXYZTJ, FINGER_I, FINGER_J);
        }
    }
//main_structure();

module main_structure_subtractor()
    difference() {
        main_structure_hull();
        extrude(-200) square(400, true);
    }

HOLES = [
//  [x, y, r]
    [-3.5, 14.5, 0],
    [-3.5, -32, -90],
    [-92, 20, 90],
    [-79.5, -47, -150],
];
HOLE_X = 0; HOLE_Y = 1; HOLE_R = 2;

module screw_sockets() {
    d = 6;
    for (i = [0:len(HOLES)-1]) {
        translate([HOLES[i][HOLE_X], HOLES[i][HOLE_Y], 3.2]) rotate([0, 0, HOLES[i][HOLE_R]]) {
            hull() {
                extrude(4) circle(d/2, $fn=FN);
                translate([20, 0, 0]) extrude(4) circle(d/2, $fn=FN);
                translate([0, 20, 0]) extrude(4) circle(d/2, $fn=FN);
            }
        }
    }
}

module screw_subtractors() {
    for (i = [0:len(HOLES)-1]) {
        translate([HOLES[i][HOLE_X], HOLES[i][HOLE_Y], 0]) rotate([0, 0, HOLES[i][HOLE_R]]) {
            union() {
                extrude(8) circle(2.8/2, $fn=FN);
                cylinder(h=3.5, r1=3.5, r2=0, $fn=FN, center=false);
            }
        }
    }
}
/*
//main_structure();
//color([1,0,0,1]) screw_sockets();
color([0,1,0,1]) screw_subtractors();
//*/

module cable_subtractors() {
    d = 3.25;
    up = d/2 + 3;
    translate([-85, 20, up]) rotate([0, 0, 90]) hull() {
        rotate([0, 90, 0]) extrude(10) circle(d/2, $fn=FN);
        translate([0, 0, -20]) rotate([0, 90, 0]) extrude(10) circle(d/2, $fn=FN);
    }
    translate([-66, 20, up]) rotate([0, 0, 90]) hull() {
        rotate([0, 90, 0]) extrude(10) circle(d/2, $fn=FN);
        translate([0, 0, -20]) rotate([0, 90, 0]) extrude(10) circle(d/2, $fn=FN);
    }
}
/*
main_structure();
color([1,0,0,1]) cable_subtractors();
*/

module cable_supports() {
    d = 2.5;
    up = d/2 + 3;
    translate([-85, 23, up]) rotate([0, 0, 90]) difference() {
        hull() {
            rotate([0, 90, 0]) extrude(10) circle((d-0.5)/2, $fn=FN);
            translate([0, 0, -20]) rotate([0, 90, 0]) extrude(10) circle((d-0.5)/2, $fn=FN);
        }
        rotate([0, 90, 0]) extrude(10) circle(d/2, $fn=FN);
    }
    translate([-66, 25, up]) rotate([0, 0, 90]) difference() {
        hull() {
            rotate([0, 90, 0]) extrude(10) circle((d-0.5)/2, $fn=FN);
            translate([0, 0, -20]) rotate([0, 90, 0]) extrude(10) circle((d-0.5)/2, $fn=FN);
        }
        rotate([0, 90, 0]) extrude(10) circle(d/2, $fn=FN);
    }
}
/*
main_structure();
color([1,0,0,1]) cable_supports();
*/

module cord_subtractor() {
    translate([-44, -35, 8]) rotate([0, 0, 90]) {
        rotate([0, 90, 0]) extrude(10) circle(5/2, $fn=FN);
    }
}

module main_housing(mirror=false)
    difference () {
        union () {
            main_structure();
            intersection() {
                main_structure_subtractor();
                screw_sockets();
            }
        }
        cable_subtractors();
        cord_subtractor();
        screw_subtractors();
        extrude(-200) square(400, true);
        if (mirror) {
            m = [1, 0, 0];
            thumb_pad_position() grid_full(THUMB_RXYZTJ, THUMB_J) mirror(m) choc(true);
            finger_pad_position() grid_full(FINGER_RXYZTJ, FINGER_J) mirror(m) choc(true);
        } else {
            thumb_pad_position() grid_full(THUMB_RXYZTJ, THUMB_J) choc(true);
            finger_pad_position() grid_full(FINGER_RXYZTJ, FINGER_J) choc(true);
        }
    }
//main_housing();
//mirror([1, 0, 0]) main_housing(true);

module bottom_plate() {
    union() {
        difference() {
            extrude(3) square(400, true);
            union() {
                difference() {
                    translate([0, 0, -200]) extrude(400) square(400, true);
                    main_structure_subtractor();
                }
                translate([ 0.5, 0, 0]) main_structure();
                translate([-0.5, 0, 0]) main_structure();
                translate([0,  0.5, 0]) main_structure();
                translate([0, -0.5, 0]) main_structure();
                translate([0, 0, -0.5]) finger_pad_position() pad(FINGER_RXYZTJ, FINGER_I, FINGER_J);
            }
            screw_subtractors();
        }
        intersection() {
            cable_supports();
            main_structure_subtractor();
        }
    }
}
//bottom_plate();
mirror([1, 0, 0]) bottom_plate();

/*
intersection() {
    bottom_plate();
    translate([-94,20,0]) cube(15, true);
}
*/

/*
module mcu_position() translate([-90, -10, 0]) rotate([90, 0, 90]) children();
//mcu_position() color([0.0, 0.7, 0.0, 1.0]) cube([35, 0.7*25.4, 1.3], false);
*/

