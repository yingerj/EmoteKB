
/////////////////////////////////
// Parameters                  //
/////////////////////////////////

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

//// Tiny value for small things to be used as edges of convex hulls.
TINY = 0.3; // Use a big TINY value to debug
//TINY = 0.001;


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
            circle(d/2, $fn=16);

// choc v2 constants
base_depth = 2.2;
nub_depth = base_depth + 2.65;
pin_depth = base_depth + 3;

module choc()
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
        pin_nub(3.4, -nub_depth);

        // r/l nubs
        pin_nub(1.9, -nub_depth, [-5.5, 0]);
        pin_nub(1.9, -nub_depth, [ 5.5, 0]);

        // pins
        pin_nub(1, -pin_depth, [0, 5.9]);
        pin_nub(1, -pin_depth, [5, 3.8]);
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

module socket() {
    difference() {
        translate([0, 0, -nub_depth])
            extrude(nub_depth) square(socket_w, true);
        choc();
        // pin rebates
        hull() {
            translate([0, 5.9, -pin_depth])
                cylinder(h = pin_depth, r = 2, $fn=32);
            translate([5, 3.8, -pin_depth])
                cylinder(h = pin_depth, r = 2, $fn=32);
        }
    }
}

module socket_corner(c=[1,1]) {
    off = socket_w/2 - TINY/ 2;
    translate([c[0]*off, c[1]*off, -nub_depth])
        linear_extrude(nub_depth)
            square(TINY, true);
}

module socket_corner_edge(c=[1,1]) {
    off = socket_w/2 + 3*TINY/ 2;
    translate([c[0]*off, c[1]*off, -nub_depth])
        linear_extrude(nub_depth)
            square(3*TINY, true);
}


/////////////////////////////////
// KB Organization             //
/////////////////////////////////


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

module grid_full(rxyztj, J)
    for (i = [0:len(rxyztj)-1]) {
        for (j = [0:J-1])
            grid(rxyztj, J, i, j)
                children();
    }

/////////////////////////////////
// Assembly & Display          //
/////////////////////////////////

module socket_corner_help(rxyztj, J, i ,j)
    translate([-2,0,0]) grid(rxyztj, J, i, j) {
        color([1.0, 0.0, 0.0, 1.0]) socket_corner([ 1, 1]);
        color([0.0, 1.0, 0.0, 1.0]) socket_corner([ 1,-1]);
        color([0.0, 0.0, 1.0, 1.0]) socket_corner([-1, 1]);
        color([0.5, 0.5, 0.5, 1.0]) socket_corner([-1,-1]);
    }


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

module pad_edge(rxyztj, I, J, t_xyz)
    union() {
        // Left/Right Sides
        for (j = [0:J-1]) {
            hull() {
                grid(rxyztj, J, I-1, j) socket_corner_edge([ 1,  1]);
                grid(rxyztj, J, I-1, j) socket_corner_edge([ 1, -1]);
                translate(t_xyz) {
                    grid(rxyztj, J, I-1, j) socket_corner_edge([ 1,  1]);
                    grid(rxyztj, J, I-1, j) socket_corner_edge([ 1, -1]);
                }
            }
            hull() {
                grid(rxyztj, J, 0, j) socket_corner_edge([-1,  1]);
                grid(rxyztj, J, 0, j) socket_corner_edge([-1, -1]);
                translate(t_xyz) {
                    grid(rxyztj, J, 0, j) socket_corner_edge([-1,  1]);
                    grid(rxyztj, J, 0, j) socket_corner_edge([-1, -1]);
                }
            }
        }
        for (j = [0:J-2]) {
            hull() {
                grid(rxyztj, J, I-1, j+1) socket_corner_edge([ 1,  1]);
                grid(rxyztj, J, I-1, j) socket_corner_edge([ 1, -1]);
                translate(t_xyz) {
                    grid(rxyztj, J, I-1, j+1) socket_corner_edge([ 1,  1]);
                    grid(rxyztj, J, I-1, j) socket_corner_edge([ 1, -1]);
                }
            }
            hull() {
                grid(rxyztj, J, 0, j+1) socket_corner_edge([-1,  1]);
                grid(rxyztj, J, 0, j) socket_corner_edge([-1, -1]);
                translate(t_xyz) {
                    grid(rxyztj, J, 0, j+1) socket_corner_edge([-1,  1]);
                    grid(rxyztj, J, 0, j) socket_corner_edge([-1, -1]);
                }
            }
        }
        // Top/Bottom Sides
        for (i = [0:I-1]) {
            hull() {
                grid(rxyztj, J, i, J-1) socket_corner_edge([-1, -1]);
                grid(rxyztj, J, i, J-1) socket_corner_edge([ 1, -1]);
                translate(t_xyz) {
                    grid(rxyztj, J, i, J-1) socket_corner_edge([-1, -1]);
                    grid(rxyztj, J, i, J-1) socket_corner_edge([ 1, -1]);
                }
            }
            hull() {
                grid(rxyztj, J, i, 0) socket_corner_edge([-1,  1]);
                grid(rxyztj, J, i, 0) socket_corner_edge([ 1,  1]);
                translate(t_xyz) {
                    grid(rxyztj, J, i, 0) socket_corner_edge([-1,  1]);
                    grid(rxyztj, J, i, 0) socket_corner_edge([ 1,  1]);
                }
            }
        }
        for (i = [0:I-2]) {
            hull() {
                grid(rxyztj, J, i+1, J-1) socket_corner_edge([-1, -1]);
                grid(rxyztj, J, i, J-1) socket_corner_edge([ 1, -1]);
                translate(t_xyz) {
                    grid(rxyztj, J, i+1, J-1) socket_corner_edge([-1, -1]);
                    grid(rxyztj, J, i, J-1) socket_corner_edge([ 1, -1]);
                }
            }
            hull() {
                grid(rxyztj, J, i+1, 0) socket_corner_edge([-1,  1]);
                grid(rxyztj, J, i, 0) socket_corner_edge([ 1,  1]);
                translate(t_xyz) {
                    grid(rxyztj, J, i+1, 0) socket_corner_edge([-1,  1]);
                    grid(rxyztj, J, i, 0) socket_corner_edge([ 1,  1]);
                }
            }
        }
    }


module finger_pad_position() {
    translate([0, 0, 2]) rotate([0, 26, 0]) children();
}
finger_pad_position() pad(FINGER_RXYZTJ, FINGER_I, FINGER_J);

module thumb_pad_position() {
    translate([-93, -38, 24]) rotate([0, -70, 39]) children();
};
thumb_pad_position() pad(THUMB_RXYZTJ, THUMB_I, THUMB_J);
//thumb_pad_position() socket_corner_help(THUMB_RXYZTJ, 1, 1);

module cap_n_key() {
    color([0.6, 0.8, 0.1, 1.0]) choc();
    color([0.8, 0.4, 0.0, 1.0]) choc_cap();
    color([0.6, 0.3, 0.0, 1.0]) translate([0, 0, -3]) choc_cap();
}
finger_pad_position() grid_full(FINGER_RXYZTJ, FINGER_J) cap_n_key();
thumb_pad_position() grid_full(THUMB_RXYZTJ, THUMB_J) cap_n_key();

difference() {
    union() {
        finger_pad_position() pad_edge(FINGER_RXYZTJ, FINGER_I, FINGER_J, [30,0,-100]);
        thumb_pad_position() pad_edge(THUMB_RXYZTJ, THUMB_I, THUMB_J, [-30,0,-80]);
    }
    extrude(-200) square(400, true);
}
