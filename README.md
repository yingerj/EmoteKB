The EmoteKB is a parameterized ergo keyboard that was inspired by the wide range of Dactyl like keyboards, in particular the DMOTE.

Why go for straight OpenSCAD rather than usign Clojure to generate it? A few reasons... OpenSCAD is ugly, but powerful, and having messed with it both directly and behind the Clojure wrapper, I'd rather just wrestle directly with OpenSCAD.

Maybe someday I'll come back and try to explain the parameterization system. Probably if I ever make a v2 of this design to achieve better ergonomics and refavtor the design.

Warning... this design may develop some nasty CSG artifacts if you tune the parmeters. I think I fixed it, but haven't really tested it beyond getting it to work enough to get the STL files to print it out (I'm not getting paid to do this).

Cheers - Jack
