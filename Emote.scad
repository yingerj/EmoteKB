

TINY = 0.001;


module orient() rotate([0, 90, 0]) children();


/////////////////////////////////
// Better Generic Modules      //
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

module choc() {
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
}

// cap dimentions guestimated with photogrametry in some cases...
module choc_cap_corner(t) translate(t) cube(TINY);
module choc_cap_half() {
    choc_cap_corner([17.53/2, -17.9/2, -2]);
    choc_cap_corner([17.53/2,  17.9/2, -2]);
    choc_cap_corner([12/2, -(17.9-2)/2, 4.23-2]);
    choc_cap_corner([12/2,  (17.9-2)/2, 3.8-2]);
}
module choc_cap()
    orient()
        translate([0, 0, 5.8])
            hull() {
                choc_cap_half();
                mirror([1, 0, 0]) choc_cap_half();
            }


/////////////////////////////////
// KB Submodules               //
/////////////////////////////////

module socket() {
    bottom_d = 2.2;
    nub_d = 2.65;
    depth = bottom_d + nub_d;
    difference() {
        orient() translate([0, 0, -depth])
            extrude(depth) square(17, true);
        choc();
        // pin rebates
        orient() translate([0, -5.9, -depth])
            cylinder(h = nub_d, r1 = 2.0, r2 = 1, $fn=32);
        orient() translate([-5, -3.8, -depth])
            cylinder(h = nub_d, r1 = 2.0, r2 = 1, $fn=32);
    }
}

module socket_corner(c=[1,1]) {
    off = 17.2/2;
    translate([c[0] * off, c[1] * off, -nub_depth])
        linear_extrude(nub_depth)
            square(TINY, true);
}

/////////////////////////////////
// Organization                //
/////////////////////////////////

module column(n, r) {
    a = 2*asin(9/r);
    a_0 = -a*(n-1)/2;
    translate([r, 0, 0])
        for (i = [0:n-1])
            rotate(i*a + a_0, [0,0,1])
                translate([-(r+5.8), 0, 0])
                    children();
}

// {r: radius, x: finger "down", y: finger "in/out", z: up/down, t: tilt}
IDX_R = 0; IDX_X = 1; IDX_Y = 2; IDX_Z = 3; IDX_T = 4;

module rows_n_columns(rows_rxyzt, columns)
    for (i = [0:len(rows_rxyzt)-1])
        translate ([rows_rxyzt[i][IDX_X], rows_rxyzt[i][IDX_Y], rows_rxyzt[i][IDX_Z]])
            rotate ([0, rows_rxyzt[i][IDX_T], 0])
                column(columns, rows_rxyzt[i][IDX_R])
                    children();


/////////////////////////////////
// Display                     //
/////////////////////////////////

module cap_n_key() {
    color([0.4, 0.7, 0.4, 1.0]) choc();
    color([0.7, 0.4, 0.4, 1.0]) choc_cap();
    color([0.7, 0.6, 0.6, 1.0]) translate([-3, 0, 0]) choc_cap();
}


rows_rxyzt = [
  //[   r   ,   x   ,   y   ,   z   ,   t   ],
    [  40   ,   2   ,   4   , 9* 9  ,   8   ],
    [  42   ,   0   ,   2   , 9* 7  ,   2   ],
    [  42   ,  -2   ,   0   , 9* 5  ,  -2   ],
    [  37   ,   3   ,  -5   , 9* 3  ,  -5   ],
    [  30   ,   7   ,  -9   , 9* 1  ,  -9   ]
];

module get_child(i) {
    children(i);
}

get_child(0)
rows_n_columns(rows_rxyzt, 3) {
    cap_n_key();
    socket();
}


