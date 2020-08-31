
/////////////////////////////////
// Parameters                  //
/////////////////////////////////

// Finger Pad
I = 5; // Columns
J = 3; // Rows

//// Grid Specification: Per Column
// RXYZT -> {r: radius, x: finger "down", y: finger "in/out", z: up/down, t: tilt}
IDX_R = 0; IDX_X = 1; IDX_Y = 2; IDX_Z = 3; IDX_T = 4;
RXYZT = [
  //[   r   ,   x   ,   y   ,   z    ,   t   ],
    [  40   ,   2   ,   4   , 9*9+1.0,   8   ],
    [  42   ,   0   ,   2   , 9*7+0.4,   2   ],
    [  42   ,  -2   ,   0   , 9*5    ,  -2   ],
    [  37   ,   3   ,  -5   , 9*3    ,  -5   ],
    [  30   ,   7   ,  -9   , 9*1-0.4,  -8   ]
];

//// Tiny value for small things to be used as edges of convex hulls.
//TINY = 1; // Use a big TINY value to debug
TINY = 0.001;


/////////////////////////////////
// Utility                     //
/////////////////////////////////

module orient() rotate([0, 90, 0]) children();

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
    orient() {
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
        pin_nub(1, -pin_depth, [0, -5.9]);
        pin_nub(1, -pin_depth, [-5, -3.8]);
    }

module choc_cap()
    orient()
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

socket_w = 17.6;

module socket() {
    bottom_d = 2.2;
    nub_d = 2.65;
    depth = bottom_d + nub_d;
    difference() {
        orient() translate([0, 0, -depth])
            extrude(depth) square(socket_w, true);
        choc();
        // pin rebates
        orient() translate([0, -5.9, -depth])
            cylinder(h = nub_d, r1 = 2.0, r2 = 1, $fn=32);
        orient() translate([-5, -3.8, -depth])
            cylinder(h = nub_d, r1 = 2.0, r2 = 1, $fn=32);
    }
}

module socket_corner(c=[1,1]) {
    off = socket_w/2;
    orient() translate([c[0] * off, c[1] * off, -nub_depth])
        linear_extrude(nub_depth)
            square(TINY, true);
}


/////////////////////////////////
// KB Organization             //
/////////////////////////////////

module finger_grid(i, j)
    // Row i-th spot
    translate ([RXYZT[i][IDX_X], RXYZT[i][IDX_Y], RXYZT[i][IDX_Z]])
        rotate ([0, RXYZT[i][IDX_T], 0]) {
            // Column j-th spot
            r = RXYZT[i][IDX_R];
            a = 2*asin(9/r);
            a0 = -a*(J-1)/2;
            // Reference to center key/key-divide for odd/even respectively
            translate([r, 0, 0])
                // Spot on the column arc
                rotate(j*a + a0, [0,0,1])
                    translate([-(r+5.8), 0, 0])
                        children();
        }

module finger_grid_full()
    for (i = [0:I-1])
        for (j = [0:J-1])
            finger_grid(i, j)
                children();

/////////////////////////////////
// Assembly & Display          //
/////////////////////////////////


module finger_pad(i) {
    union() {
        // Sockets
        finger_grid_full()
            socket();
        // Horizontal Web
        for (i = [0:I-2])
            for (j = [0:J-1])
                hull() {
                    finger_grid(i, j) socket_corner([1, 1]);
                    finger_grid(i, j) socket_corner([1, -1]);
                    finger_grid(i+1, j) socket_corner([-1, 1]);
                    finger_grid(i+1, j) socket_corner([-1, -1]);
                }
        // Vertical Web
        for (i = [0:I-1])
            for (j = [0:J-2])
                hull() {
                    finger_grid(i, j+1) socket_corner([1, 1]);
                    finger_grid(i, j+1) socket_corner([-1, 1]);
                    finger_grid(i, j) socket_corner([1, -1]);
                    finger_grid(i, j) socket_corner([-1, -1]);
                }
        // Center Web
        for (i = [0:I-2])
            for (j = [0:J-2])
                hull() {
                    finger_grid(i+1, j+1) socket_corner([-1,1]);
                    finger_grid(i+1, j) socket_corner([-1,-1]);
                    finger_grid(i, j+1) socket_corner([1,1]);
                    finger_grid(i, j) socket_corner([1,-1]);
                }
    }
}

module cap_n_key() {
    //color([0.4, 0.7, 0.4, 1.0]) choc();
    //color([0.7, 0.4, 0.4, 1.0]) choc_cap();
    color([0.7, 0.6, 0.6, 1.0]) translate([-3, 0, 0]) choc_cap();
}

difference() {
    finger_pad();
    finger_grid_full() cap_n_key();
}

module socket_corner_help()
    translate([-2,0,0])finger_grid(2,1) {
        color([1.0, 0.0, 0.0, 1.0]) socket_corner([1,1]);
        color([0.0, 1.0, 0.0, 1.0]) socket_corner([1,-1]);
        color([0.0, 0.0, 1.0, 1.0]) socket_corner([-1,1]);
        color([0.5, 0.5, 0.5, 1.0]) socket_corner([-1,-1]);
    }
//socket_corner_help();
