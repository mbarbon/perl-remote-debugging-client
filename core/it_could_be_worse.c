/*

   Alternative to copying and patching pp_entersub (requires Perl 5.20).

   The goal is to run a C callback inside the newly-entered scope for
   the sub, without the overhead of calling a Perl subroutine (either
   pure-Perl or XS) and performing the call for both pure-Perl and XS
   subroutines.

   - hook pp_entersub and attaches magic to PL_DBsub
   - set GvCV(PL_DBsub) to a dummy non-NULL value, so Perl enters the
     "we have a DB::sub sub branch"
   - set PERLDBf_NONAME so Perl_get_db_sub skips most of the work
     and sets PL_DBsub as a reference to the CV
   - when the SET magic is triggered from inside Perl_get_db_sub,
     use a patched version of it to do the work that would have been
     done if PERLDBf_NONAME were unset
   - do the actual useful work
   - set GvCV(PL_DBsub) to the actual sub being called, thus making
     the "we have a DB::sub sub branch" an effective no-op (except for
     the "useful work" in the previous point)

 */

MGVTBL my_vtbl;

/* omitting some private functions/macros lifted as-is from core */

static void
my_get_db_sub(pTHX_ SV **svp, CV *cv)
{
    SV * const dbsv = GvSVn(PL_DBsub);
    const bool save_taint = TAINT_get;

    /* When we are called from pp_goto (svp is null),
     * we do not care about using dbsv to call CV;
     * it's for informational purposes only.
     */

    PERL_ARGS_ASSERT_GET_DB_SUB;

    TAINT_set(FALSE);
    /* save_item(dbsv); -- this is the reason of the whole copy-paste */
    if (1 /* !PERLDB_SUB_NN -- we only care about this branch */) {
	GV *gv = CvGV(cv);

	if (!svp) {
	    gv_efullname3(dbsv, gv, NULL);
	}
	else if ( (CvFLAGS(cv) & (CVf_ANON | CVf_CLONED))
	     || strEQ(GvNAME(gv), "END")
	     || ( /* Could be imported, and old sub redefined. */
		 (GvCV(gv) != cv || !S_gv_has_usable_name(aTHX_ gv))
		 &&
		 !( (SvTYPE(*svp) == SVt_PVGV)
		    && (GvCV((const GV *)*svp) == cv)
		    /* Use GV from the stack as a fallback. */
		    && S_gv_has_usable_name(aTHX_ gv = (GV *)*svp)
		  )
		)
	) {
	    /* GV is potentially non-unique, or contain different CV. */
	    SV * const tmp = newRV(MUTABLE_SV(cv));
	    sv_setsv(dbsv, tmp);
	    SvREFCNT_dec(tmp);
	}
	else {
	    /* sv_sethek(dbsv, HvENAME_HEK(GvSTASH(gv))); -- backwards compat */
	    sv_setpvs(dbsv, "");
	    sv_catpvn(
		dbsv, HvENAME(GvSTASH(gv)), HvNAMELEN(GvSTASH(gv))
	    );
	    sv_catpvs(dbsv, "::");
	    /* sv_cathek(dbsv, GvNAME_HEK(gv)); -- backwards compat */
	    sv_catpvn(
		dbsv, GvNAME(gv), GvNAMELEN(gv)
	    );
	    if (GvNAMEUTF8(gv) || HvNAMEUTF8(GvSTASH(gv)))
		SvUTF8_on(dbsv);
	}
    }
    else { /* -- this branch is never taken */
	const int type = SvTYPE(dbsv);
	if (type < SVt_PVIV && type != SVt_IV)
	    sv_upgrade(dbsv, SVt_PVIV);
	(void)SvIOK_on(dbsv);
	SvIV_set(dbsv, PTR2IV(cv));	/* Do it the quickest way  */
    }
    /* SvSETMAGIC(dbsv); -- inside mg_set(), don't reinvoke magic */
    TAINT_IF(save_taint);
#ifdef NO_TAINT_SUPPORT
    PERL_UNUSED_VAR(save_taint);
#endif
}

static int save_cv(pTHX_ SV *sv, MAGIC *mg) {
    /*
       an entersub can have op_type 0 when constructed by Perl_call_sv,
       and we can arrive here via pp_goto or unwinding at end of scope
     */
    if (PL_op && PL_op->op_type && PL_op->op_type != OP_ENTERSUB) {
        return 0;
    }
    /* unwinding at end of XSUB (so op is an ENTERSUB) */
    if (!mg->mg_obj) {
       return 0;
    }

    dMY_CXT;
    IV current_depth = SvIV(GvSVn(MY_CXT.stack_depth)) + 1;
    SV *xsv = mg->mg_obj;
    CV *cv = INT2PTR(CV *, SvIVX(sv));
    mg->mg_obj = NULL;
    my_get_db_sub(aTHX_ &xsv, cv);
    GvCV_set(PL_DBsub, cv);

    /* useful work */
    bool in_debugger = before_call(aTHX_ aMY_CXT_ current_depth);
    if (!in_debugger) {
        IV *cxt;
        Newx(cxt, 1, IV);
        *cxt = current_depth;
        SAVEDESTRUCTOR_X(exit_break, cxt);
    }
    /* end of useful work */

    return 0;
}

static OP *
pp_db_entersub(pTHX) {
    SV *sub = GvSV(PL_DBsub);
    if (!(PL_op->op_private & OPpENTERSUB_DB) || !sub) {
        return orig_entersub(aTHX);
    } else {
        dSP; dPOPss;
        MAGIC *mg = SvTYPE(sub) >= SVt_PVMG ? mg_findext(sub, PERL_MAGIC_ext, &my_vtbl) : NULL;

        if (mg == NULL)
            mg = sv_magicext(sub, NULL, PERL_MAGIC_ext, &my_vtbl, NULL, 0);

        PL_perldb |= PERLDBf_NONAME;
        GvCV_set(PL_DBsub, (CV *) 1);
        /*
           XXX here we should run entersub preamble (up to "retry:")
           this is good enough for now
          */
        mg->mg_obj = sv;

        PUSHs((SV *) sv);
        OP *ret = orig_entersub(aTHX);
        /* so caller() does not skip the frame */
        /* XXX this is too late for XSUB: fix it */
        GvCV_set(PL_DBsub, 0);

        return ret;
    }
}

BOOT:
    my_vtbl.svt_set = save_cv;
