#if 0
    /* simplify code generation */

#elif ((PERL_VERSION == 10 && PERL_PATCHLEVEL >= 0) || (PERL_VERSION > 10)) && ((PERL_VERSION == 10 && PERL_PATCHLEVEL <= 0) || (PERL_VERSION < 10))
    #include "pp_hot-5.10.0-5.10.0.c"

#elif ((PERL_VERSION == 10 && PERL_PATCHLEVEL >= 1) || (PERL_VERSION > 10)) && ((PERL_VERSION == 10 && PERL_PATCHLEVEL <= 1) || (PERL_VERSION < 10))
    #include "pp_hot-5.10.1-5.10.1.c"

#elif ((PERL_VERSION == 12 && PERL_PATCHLEVEL >= 0) || (PERL_VERSION > 12)) && ((PERL_VERSION == 12 && PERL_PATCHLEVEL <= 5) || (PERL_VERSION < 12))
    #include "pp_hot-5.12.0-5.12.5.c"

#elif ((PERL_VERSION == 14 && PERL_PATCHLEVEL >= 0) || (PERL_VERSION > 14)) && ((PERL_VERSION == 14 && PERL_PATCHLEVEL <= 4) || (PERL_VERSION < 14))
    #include "pp_hot-5.14.0-5.14.4.c"

#elif ((PERL_VERSION == 16 && PERL_PATCHLEVEL >= 0) || (PERL_VERSION > 16)) && ((PERL_VERSION == 16 && PERL_PATCHLEVEL <= 3) || (PERL_VERSION < 16))
    #include "pp_hot-5.16.0-5.16.3.c"

#elif ((PERL_VERSION == 18 && PERL_PATCHLEVEL >= 0) || (PERL_VERSION > 18)) && ((PERL_VERSION == 18 && PERL_PATCHLEVEL <= 0) || (PERL_VERSION < 18))
    #include "pp_hot-5.18.0-5.18.0.c"

#elif ((PERL_VERSION == 18 && PERL_PATCHLEVEL >= 1) || (PERL_VERSION > 18)) && ((PERL_VERSION == 18 && PERL_PATCHLEVEL <= 4) || (PERL_VERSION < 18))
    #include "pp_hot-5.18.1-5.18.4.c"

#elif ((PERL_VERSION == 20 && PERL_PATCHLEVEL >= 0) || (PERL_VERSION > 20)) && ((PERL_VERSION == 20 && PERL_PATCHLEVEL <= 3) || (PERL_VERSION < 20))
    #include "pp_hot-5.20.0-5.20.3.c"

#elif ((PERL_VERSION == 22 && PERL_PATCHLEVEL >= 0) || (PERL_VERSION > 22)) && ((PERL_VERSION == 22 && PERL_PATCHLEVEL <= 1) || (PERL_VERSION < 22))
    #include "pp_hot-5.22.0-5.22.1.c"

#elif ((PERL_VERSION == 22 && PERL_PATCHLEVEL >= 2) || (PERL_VERSION > 22)) && ((PERL_VERSION == 22 && PERL_PATCHLEVEL <= 2) || (PERL_VERSION < 22))
    #include "pp_hot-5.22.2-5.22.2.c"

#elif ((PERL_VERSION == 24 && PERL_PATCHLEVEL >= 0) || (PERL_VERSION > 24)) && ((PERL_VERSION == 24 && PERL_PATCHLEVEL <= 0) || (PERL_VERSION < 24))
    #include "pp_hot-5.24.0-5.24.0.c"


#else
    #define NO_PATCHED_ENTERSUB
#endif
