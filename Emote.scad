
/////////////////////////////////
// Parameters                  //
/////////////////////////////////

//// Grid Specification: Per Column
// RXYZTJ -> {r: radius, x: finger "down", y: finger "in/out", z: up/down, t: tilt}
IDX_R = 0; IDX_X = 1; IDX_Y = 2; IDX_Z = 3; IDX_T = 4; IDX_J = 5;

// Finger Pad
FINGER_I = 5; // Columns
FINGER_J = 3; // Rows
FINGER_RXYZTJ = [
  //[   r   ,   x   ,   y   ,   z    ,   t   ,  j         ],
    [  40   ,   2   ,   4   , 9*9+1.0,   8   ,  FINGER_J  ],
    [  42   ,   0   ,   2   , 9*7+0.4,   2   ,  FINGER_J  ],
    [  42   ,  -2   ,   0   , 9*5    ,  -2   ,  FINGER_J  ],
    [  37   ,   3   ,  -5   , 9*3    ,  -5   ,  FINGER_J  ],
    [  30   ,   7   ,  -9   , 9*1-0.4,  -8   ,  FINGER_J  ]
];
// Finger Pad
THUMB_I = 3; // Columns
THUMB_RXYZTJ = [
  //[   r   ,   x   ,   y   ,   z  ,   t    ,  j  ],
    [  37   ,   4   ,   0   , 20   ,   24   ,  2  ],
    [  40   ,   0   ,   0   , 0    ,   0    ,  3  ],
    [  37   ,   4   ,   0   , -20  ,  -24   ,  2  ]
];

//// Tiny value for small things to be used as edges of convex hulls.
TINY = 1; // Use a big TINY value to debug
//TINY = 0.001;


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


module grid(rxyztj, i, j)
    // Row i-th spot
    translate ([rxyztj[i][IDX_X], rxyztj[i][IDX_Y], rxyztj[i][IDX_Z]])
        rotate ([0, rxyztj[i][IDX_T], 0]) {
            // Column j-th spot
            r = rxyztj[i][IDX_R];
            a = 2*asin(9/r);
            a0 = -a*(rxyztj[i][IDX_J]-1)/2;
            // Reference to center key/key-divide for odd/even respectively
            translate([r, 0, 0])
                // Spot on the column arc
                rotate(j*a + a0, [0,0,1])
                    translate([-(r+5.8), 0, 0])
                        children();
        }

module grid_full(rxyztj)
    for (i = [0:len(rxyztj)-1]) {
        for (j = [0:rxyztj[i][IDX_J]-1])
            grid(rxyztj, i, j)
                children();
    }

/////////////////////////////////
// Assembly & Display          //
/////////////////////////////////

module socket_corner_help(rxyztj, i ,j)
    translate([-2,0,0])grid(rxyztj, i, j) {
        color([1.0, 0.0, 0.0, 1.0]) socket_corner([1,1]);
        color([0.0, 1.0, 0.0, 1.0]) socket_corner([1,-1]);
        color([0.0, 0.0, 1.0, 1.0]) socket_corner([-1,1]);
        color([0.5, 0.5, 0.5, 1.0]) socket_corner([-1,-1]);
    }

module finger_pad_position() {
    translate([0, 0, 6.5]) rotate([0, -57, 0]) rotate([0, 0, -13]) children();
}
module finger_pad() {
    union() {
        // Sockets
        grid_full(FINGER_RXYZTJ)
            socket();
        // Horizontal Web
        for (i = [0:FINGER_I-2])
            for (j = [0:FINGER_RXYZTJ[i][IDX_J]-1])
                hull() {
                    grid(FINGER_RXYZTJ, i, j) socket_corner([1, 1]);
                    grid(FINGER_RXYZTJ, i, j) socket_corner([1, -1]);
                    grid(FINGER_RXYZTJ, i+1, j) socket_corner([-1, 1]);
                    grid(FINGER_RXYZTJ, i+1, j) socket_corner([-1, -1]);
                }
        // Vertical Web
        for (i = [0:FINGER_I-1])
            for (j = [0:FINGER_RXYZTJ[i][IDX_J]-2])
                hull() {
                    grid(FINGER_RXYZTJ, i, j+1) socket_corner([1, 1]);
                    grid(FINGER_RXYZTJ, i, j+1) socket_corner([-1, 1]);
                    grid(FINGER_RXYZTJ, i, j) socket_corner([1, -1]);
                    grid(FINGER_RXYZTJ, i, j) socket_corner([-1, -1]);
                }
        // Center Web
        for (i = [0:FINGER_I-2])
            for (j = [0:FINGER_RXYZTJ[i][IDX_J]-2])
                hull() {
                    grid(FINGER_RXYZTJ, i+1, j+1) socket_corner([-1,1]);
                    grid(FINGER_RXYZTJ, i+1, j) socket_corner([-1,-1]);
                    grid(FINGER_RXYZTJ, i, j+1) socket_corner([1,1]);
                    grid(FINGER_RXYZTJ, i, j) socket_corner([1,-1]);
                }
    }
}
//finger_pad_position() finger_pad();

module thumb_pad_position() {
    translate([-90, -30, 33]) rotate([0, 0, -60]) rotate([20, -24, -90]) children();
};
module thumb_pad() {
    union() {
        // Sockets
        grid_full(THUMB_RXYZTJ)
            socket();
        // Vertical Web
        for (i = [0:THUMB_I-1])
            for (j = [0:THUMB_RXYZTJ[i][IDX_J]-2])
                color([i*0.4, j*0.3, 0.5, 1.0]) hull() {
                    grid(THUMB_RXYZTJ, i, j+1) socket_corner([1, 1]);
                    grid(THUMB_RXYZTJ, i, j+1) socket_corner([-1, 1]);
                    grid(THUMB_RXYZTJ, i, j) socket_corner([1, -1]);
                    grid(THUMB_RXYZTJ, i, j) socket_corner([-1, -1]);
                }
        for (i = [0:THUMB_I-2]) {
            J = max(THUMB_RXYZTJ[i][IDX_J], THUMB_RXYZTJ[i+1][IDX_J]);
            di = THUMB_RXYZTJ[i][IDX_J] > THUMB_RXYZTJ[i+1][IDX_J] ? -1 : 1;
            // Horizontal Web
            for (j = [0:J-1])
                color([i*0.4, j*0.3, 0.5, 1.0]) hull() {
                    grid(THUMB_RXYZTJ, i, j) socket_corner([1, 1]);
                    grid(THUMB_RXYZTJ, i, j) socket_corner([1, -1]);
                    grid(THUMB_RXYZTJ, i+1, j) socket_corner([-1, 1]);
                    grid(THUMB_RXYZTJ, i+1, j) socket_corner([-1, -1]);
                }
            // Center Web
            for (j = [0:J-3])
                color([i*0.4, j*0.3, 0.0, 1.0]) hull() {
                    grid(THUMB_RXYZTJ, i+1, j+1) socket_corner([-1,1]);
                    grid(THUMB_RXYZTJ, i+1, j) socket_corner([-1,-1]);
                    grid(THUMB_RXYZTJ, i, j+1) socket_corner([1,1]);
                    grid(THUMB_RXYZTJ, i, j) socket_corner([1,-1]);
                }
        }
    }
};
thumb_pad_position() thumb_pad();
thumb_pad_position() socket_corner_help(THUMB_RXYZTJ, 1, 1);

module cap_n_key() {
    //color([0.4, 0.7, 0.4, 1.0]) choc();
    //color([0.7, 0.4, 0.4, 1.0]) choc_cap();
    color([0.7, 0.6, 0.6, 1.0]) translate([-3, 0, 0]) choc_cap();
}
//finger_pad_position() grid_full(FINGER_RXYZTJ) cap_n_key();
//thumb_pad_position() grid_full(THUMB_RXYZTJ) cap_n_key();

difference() {
    thumb_pad_position() thumb_pad();
    thumb_pad_position() grid_full(THUMB_RXYZTJ) cap_n_key();
}

