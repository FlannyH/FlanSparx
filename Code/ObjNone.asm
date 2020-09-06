SECTION "ObjNone", ROM0
;Objects with no update method still need a dummy update method, so it just returns after doing nothing
ObjNone_Update:
    ret