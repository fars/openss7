/*****************************************************************************

 @(#) $RCSfile$ $Name$($Revision$) $Date$

 -----------------------------------------------------------------------------

 Copyright (c) 2001-2007  OpenSS7 Corporation <http://www.openss7.com/>
 Copyright (c) 1997-2000  Brian F. G. Bidulock <bidulock@openss7.org>

 All Rights Reserved.

 This program is free software: you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation, version 3 of the license.

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 details.

 You should have received a copy of the GNU General Public License along with
 this program.  If not, see <http://www.gnu.org/licenses/>, or write to the
 Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 -----------------------------------------------------------------------------

 U.S. GOVERNMENT RESTRICTED RIGHTS.  If you are licensing this Software on
 behalf of the U.S. Government ("Government"), the following provisions apply
 to you.  If the Software is supplied by the Department of Defense ("DoD"), it
 is classified as "Commercial Computer Software" under paragraph 252.227-7014
 of the DoD Supplement to the Federal Acquisition Regulations ("DFARS") (or any
 successor regulations) and the Government is acquiring only the license rights
 granted herein (the license rights customarily provided to non-Government
 users).  If the Software is supplied to any unit or agency of the Government
 other than DoD, it is classified as "Restricted Computer Software" and the
 Government's rights in the Software are defined in paragraph 52.227-19 of the
 Federal Acquisition Regulations ("FAR") (or any successor regulations) or, in
 the cases of NASA, in paragraph 18.52.227-86 of the NASA Supplement to the FAR
 (or any successor regulations).

 -----------------------------------------------------------------------------

 Commercial licensing and support of this software is available from OpenSS7
 Corporation at a fee.  See http://www.openss7.com/

 -----------------------------------------------------------------------------

 Last Modified $Date$ by $Author$

 -----------------------------------------------------------------------------

 $Log$
 *****************************************************************************/

#ident "@(#) $RCSfile$ $Name$($Revision$) $Date$"

static char const ident[] = "$RCSfile$ $Name$($Revision$) $Date$";

/* oc.c - Object Class routines */

#ifndef lint
static char *rcsid =
    "Header: /xtel/isode/isode/dsap/common/RCS/oc.c,v 9.0 1992/06/16 12:12:39 isode Rel";
#endif

/*
 * Header: /xtel/isode/isode/dsap/common/RCS/oc.c,v 9.0 1992/06/16 12:12:39 isode Rel
 *
 *
 * Log: oc.c,v
 * Revision 9.0  1992/06/16  12:12:39  isode
 * Release 8.0
 *
 */

/*
 *                                NOTICE
 *
 *    Acquisition, use, and distribution of this module and related
 *    materials are subject to the restrictions of a license agreement.
 *    Consult the Preface in the User's Manual for the full terms of
 *    this agreement.
 *
 */

/* LINTLIBRARY */

#include "quipu/util.h"
#include "quipu/entry.h"
#include "tailor.h"

extern LLog *log_dsap;
extern short oc_sntx;
extern IFP oc_hier;
extern IFP oc_avsprint;

static add_hierarchy();

objectclass *
oc_add(oid)
	OID oid;
{
	oid_table *Current;
	extern objectclass ocOIDTable[];
	extern int ocNumEntries;

	Current = &ocOIDTable[ocNumEntries].oc_ot;
	if (oid == NULLOID)
		Current->ot_oid = NULLOID;
	else
		Current->ot_oid = oid_cpy(oid);
	Current->ot_name = strdup(oid2ode_aux(oid, 0));
	Current->ot_stroid = strdup(sprintoid(oid));
	(void) add_entry_aux(Current->ot_name, (caddr_t) &ocOIDTable[ocNumEntries], 3, NULLCP);
	ocOIDTable[ocNumEntries].oc_hierachy = NULLOCSEQ;
	ocOIDTable[ocNumEntries].oc_may = NULLTABLE_SEQ;
	ocOIDTable[ocNumEntries].oc_must = NULLTABLE_SEQ;
	return (&ocOIDTable[ocNumEntries++]);
}

objectclass *
str2oc(str)
	char *str;
{
	char *ptr;
	char *get_oid();
	objectclass *oc;

	if ((oc = name2oc(str)) != NULLOBJECTCLASS)
		return (oc);

	/* unknown object class -- need to add to table */
	if ((ptr = get_oid(str)) == NULLCP) {
		parse_error("Object class %s unknown", str);
		return (NULLOBJECTCLASS);
	}

	return (oc_add(str2oid(ptr)));
}

static AV_Sequence
new_oc_avs(oc)
	objectclass *oc;
{
	AV_Sequence avs;

	avs = avs_comp_alloc();
	avs->avseq_next = NULLAV;
	avs->avseq_av.av_syntax = oc_sntx;
	avs->avseq_av.av_struct = (caddr_t) oc;
	return (avs);
}

static AV_Sequence
str2oc_hier(str)
	char *str;
{
	AV_Sequence avs = NULLAV;
	objectclass *oc;
	char *ptr, *save, val;

	str = SkipSpace(str);

	while ((ptr = index(str, '&')) != 0) {
		save = ptr++;
		save--;
		if (!isspace(*save))
			save++;
		val = *save;
		*save = 0;

		if ((oc = str2oc(str)) == NULLOBJECTCLASS)
			return (NULLAV);
		if (avs == NULLAV)
			avs = new_oc_avs(oc);
		else
			add_oc_avs(oc, &avs);
		add_hierarchy(oc, &avs);

		*save = val;
		str = SkipSpace(ptr);
	}

	if ((oc = str2oc(str)) == NULLOBJECTCLASS)
		return (NULLAV);
	if (avs == NULLAV)
		avs = new_oc_avs(oc);
	else
		add_oc_avs(oc, &avs);
	add_hierarchy(oc, &avs);

	return (avs);
}

add_oc_avs(oc, avsp)
	objectclass *oc;
	AV_Sequence *avsp;
{
	AV_Sequence loop;
	objectclass *ocp;

	/* see if we already have oc in heirarchy ... */

	for (loop = *avsp; loop != NULLAV; loop = loop->avseq_next) {
		ocp = (objectclass *) loop->avseq_av.av_struct;
		if (oc == ocp)
			return;
	}
	*avsp = avs_merge(*avsp, new_oc_avs(oc));
}

static
add_hierarchy(oc, avsp)
	objectclass *oc;
	AV_Sequence *avsp;
{
	struct oc_seq *oidseq;

	for (oidseq = oc->oc_hierachy; oidseq != NULLOCSEQ; oidseq = oidseq->os_next) {
		add_oc_avs(oidseq->os_oc, avsp);
		add_hierarchy(oidseq->os_oc, avsp);
	}
}

static
in_hierarchy(a, b)
	AV_Sequence a, b;
{
	struct oc_seq *oidseq;
	objectclass *oca, *ocb;

	if ((a == NULLAV) || (a->avseq_av.av_syntax != oc_sntx) || (a->avseq_av.av_struct == NULL))
		return (FALSE);

	if ((b == NULLAV) || (b->avseq_av.av_syntax != oc_sntx) || (b->avseq_av.av_struct == NULL))
		return (FALSE);

	oca = (objectclass *) a->avseq_av.av_struct;
	ocb = (objectclass *) b->avseq_av.av_struct;

	for (oidseq = ocb->oc_hierachy; oidseq != NULLOCSEQ; oidseq = oidseq->os_next)
		if (objclass_cmp(oca, oidseq->os_oc) == 0)
			return (TRUE);

	return (FALSE);
}

static
oc_print_avs(ps, avs, format)		/* need to use this somehow !!! */
	PS ps;
	AV_Sequence avs;
	int format;
{
	AV_Sequence newavs;
	char found;
	char printed = FALSE;

	if (avs == NULLAV)
		return;

	if (format != READOUT)
		DLOG(log_dsap, LLOG_EXCEPTIONS, ("invalid call to oc_print"));

	for (; avs->avseq_next != NULLAV; avs = avs->avseq_next) {
		found = FALSE;
		for (newavs = avs->avseq_next; newavs != NULLAV; newavs = newavs->avseq_next)
			if (in_hierarchy(avs, newavs) == TRUE) {
				found = TRUE;
				break;
			}

		if (found == FALSE) {
			if (printed == TRUE)
				ps_print(ps, " & ");
			AttrV_print(ps, &avs->avseq_av, format);
			printed = TRUE;
		}
	}

	if (printed == TRUE)
		ps_print(ps, " & ");
	AttrV_print(ps, &avs->avseq_av, format);
}

objectclass_cmp(a, b)
	objectclass *a, *b;
{
	/* macro ! */

	return objclass_cmp(a, b);
}

static objectclass *
oc_cpy(oc)
	objectclass *oc;
{
	return (oc);		/* static table !!! */
}

check_in_oc(oid, avs)
	OID oid;
	AV_Sequence avs;
{
	objectclass *oc;

	for (; avs != NULLAV; avs = avs->avseq_next) {
		oc = (objectclass *) avs->avseq_av.av_struct;
		if (oc == NULLOBJECTCLASS)
			continue;
		if (oid_cmp(oid, oc->oc_ot.ot_oid) == 0)
			return (TRUE);
	}

	return (FALSE);
}

/* ARGSUSED */
static
oc_free(oc)
	objectclass *oc;
{
	;			/* static table !!! */
}

static PE
oc_enc(oc)
	objectclass *oc;
{
	return (oid2prim(oc->oc_ot.ot_oid));
}

static objectclass *
oc_dec(pe)
	PE pe;
{
	OID oid;
	objectclass *oc;

	if (!test_prim_pe(pe, PE_CLASS_UNIV, PE_PRIM_OID))
		return NULLOBJECTCLASS;

	if ((oid = prim2oid(pe)) == NULLOID)
		return NULLOBJECTCLASS;

	if ((oc = oid2oc(oid)) != NULLOBJECTCLASS)
		return (oc);

	return (oc_add(oid));
}

oc_print(ps, oc, format)
	PS ps;
	objectclass *oc;
	int format;
{
	extern int oidformat;

	if (format != READOUT)
		ps_printf(ps, "%s", oc2name(oc, OIDPART));
	else
		ps_printf(ps, "%s", oc2name(oc, oidformat));
}

objectclass_syntax()
{

	oc_sntx = add_attribute_syntax("objectclass",
				       (IFP) oc_enc, (IFP) oc_dec,
				       (IFP) str2oc, oc_print,
				       (IFP) oc_cpy, objectclass_cmp,
				       oc_free, NULLCP, NULLIFP, FALSE);

	oc_hier = (IFP) str2oc_hier;
	oc_avsprint = (IFP) oc_print_avs;
	want_oc_hierarchy();

}