/*
 * Note: this file originally auto-generated by mib2c using
 *       version : 1.17 $ of : mfd-data-access.m2c,v $
 *
 * $Id:$
 */
#ifndef STRSTATSTABLE_DATA_ACCESS_H
#define STRSTATSTABLE_DATA_ACCESS_H

#ifdef __cplusplus
extern "C" {
#endif

/* *********************************************************************
 * function declarations
 */

/* *********************************************************************
 * Table declarations
 */
/**********************************************************************
 **********************************************************************
 ***
 *** Table strStatsTable
 ***
 **********************************************************************
 **********************************************************************/
/*
 * OPENSS7-STREAMS-MIB::strStatsTable is subid 1 of strStats.
 * Its status is Current.
 * OID: .1.3.6.1.4.1.29591.1.1.1.1.1.5.1, length: 14
*/

        int strStatsTable_init_data(strStatsTable_registration * strStatsTable_reg);

        /*
         ***************************************************
         ***             START EXAMPLE CODE              ***
         ***---------------------------------------------***/
/* *********************************************************************
 * Since we have no idea how you really access your data, we'll go with
 * a worst case example: a flat text file.
 */
#define MAX_LINE_SIZE 256
        /*
         ***---------------------------------------------***
         ***              END  EXAMPLE CODE              ***
         ***************************************************/

/**
 * loop context
 *
 * TODO:
 * define loop context structure
 *
 *  Since the actual loop is in the MFD handler, a loop contex parameter
 *  is provided to help you keep track of where you are in between calls
 *  to functions that you wrote and the master MFD handler calls. The
 *  structure of this context is user defineable, and is defined in the
 *  file strStatsTable_data_access.h.
 *
 *  E.G., if your data is stored in a linked list, the obvious thing you
 *  want to know from one function call to the next is your current
 *  position in the linked list.  Thus the easiest context to use is a
 *  pointer within the linked list.  For an array, the current index to
 *  that array would be easiest.
 *
 *  The funtion calls are actually passed a reference to the loop
 *  context, to allow the loop context to be allocated memory. Here are
 *  some simple examples definitions for various data formats. These
 *  definitions are used in examples later on.
 *
 */
        typedef struct strStatsTable_loop_context_s {
                /*
                 * temporary context used during iteration
                 */
                strStatsTable_rowreq_ctx *rowreq_ctx;

                /*
                 * this example code is based on a data source that is a
                 * text file to be read and parsed.
                 */
                FILE *filep;
                char line[MAX_LINE_SIZE];
        } strStatsTable_loop_context;

/*
 * define a reference to the loop context
 *
 * NOTE: DO NOT ADD ITEMS TO THIS STRUCTURE!
 */
        typedef struct strStatsTable_ref_loop_ctx_s {
                strStatsTable_loop_context *loop_ctx;
        } strStatsTable_ref_loop_ctx;

        int strStatsTable_loop_get_first(strStatsTable_registration * strStatsTable_reg,
                                         strStatsTable_ref_loop_ctx * loop_ctx_ref,
                                         strStatsTable_ref_rowreq_ctx * rowreq_ctx_ref);
        int strStatsTable_loop_get_next(strStatsTable_registration * strStatsTable_reg,
                                        strStatsTable_ref_loop_ctx * loop_ctx_ref,
                                        strStatsTable_ref_rowreq_ctx * rowreq_ctx_ref);
        int strStatsTable_loop_get_data(strStatsTable_registration * strStatsTable_reg,
                                        strStatsTable_ref_loop_ctx * loop_ctx_ref,
                                        strStatsTable_ref_rowreq_ctx * rowreq_ctx_ref);
        int strStatsTable_loop_save_position(strStatsTable_registration * strStatsTable_reg,
                                             strStatsTable_ref_loop_ctx * loop_ctx_ref,
                                             strStatsTable_ref_loop_ctx * save_loop_ctx_ref,
                                             int reuse);
        int strStatsTable_loop_cleanup_context(strStatsTable_registration * strStatsTable_reg,
                                               strStatsTable_ref_loop_ctx * ref);

        int strStatsTable_row_prep(strStatsTable_rowreq_ctx * rowreq_ctx);

#ifdef __cplusplus
}
#endif
#endif                                  /* STRSTATSTABLE_DATA_ACCESS_H */