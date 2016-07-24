#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define MY_CXT_KEY "perl5db::_guts" XS_VERSION

typedef struct {
    SV *ldebug;
} my_cxt_t;

START_MY_CXT

#define dblog(string)                   \
    STMT_START {                        \
        if (SvIV(MY_CXT.ldebug)) {      \
            const char *arg = (string); \
            PUTBACK;                    \
            do_dblog(arg);              \
            SPAGAIN;                    \
        }                               \
    } STMT_END

void do_dblog(const char *string) {
    dSP;

    EXTEND(SP, 1);

    PUSHMARK(SP);
    PUSHs(sv_2mortal(newSVpv(string, 0)));
    PUTBACK;

    call_pv("DB::dblog", G_VOID | G_DISCARD | G_NODEBUG);
}

void reinit_my_cxt(pMY_CXT) {
    MY_CXT.ldebug = get_sv("DB::ldebug", 0);

    call_pv("DB::setup_lexicals", G_VOID | G_DISCARD | G_NODEBUG);
}

MODULE=dbgp_helper::perl5db PACKAGE=DB::XS

void
setup_lexicals(SV *ldebug)
  PREINIT:
    dMY_CXT;
  CODE:
    MY_CXT.ldebug = SvRV(ldebug);

void
CLONE(...)
  CODE:
    MY_CXT_CLONE;
    reinit_my_cxt();

BOOT:
    MY_CXT_INIT;
    reinit_my_cxt();
