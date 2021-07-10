//
//  rank.c
//  AccessToInsight
//
//  Created by Bill Parousis on 2021-06-23.
//

#include "rank.h"
#include <assert.h>

double rankFunc(unsigned int *aMatchinfo) {
    int nCol;                       /* Number of columns in the table */
    int nPhrase;                    /* Number of phrases in the query */
    int iPhrase;                    /* Current phrase */
    double score = 0.0;             /* Value to return */
    double defaultWeight = 1.0;
    
    assert(sizeof(int) == 4);
    
    /* Check that the number of arguments passed to this function is correct.
     ** If not, jump to wrong_number_args. Set aMatchinfo to point to the array
     ** of unsigned integer values returned by FTS function matchinfo. Set
     ** nPhrase to contain the number of reportable phrases in the users full-text
     ** query, and nCol to the number of columns in the table.
     */
    nPhrase = aMatchinfo[0];
    nCol = aMatchinfo[1];
    
    /* Iterate through each phrase in the users query. */
    for(iPhrase = 0; iPhrase < nPhrase; iPhrase++){
        int iCol;                     /* Current column */
        
        /* Now iterate through each column in the users query. For each column,
         ** increment the relevancy score by:
         **
         **   (<hit count> / <global hit count>) * <column weight>
         **
         ** aPhraseinfo[] points to the start of the data for phrase iPhrase. So
         ** the hit count and global hit counts for each column are found in
         ** aPhraseinfo[iCol*3] and aPhraseinfo[iCol*3+1], respectively.
         */
        unsigned int *aPhraseinfo = &aMatchinfo[2 + iPhrase*nCol * 3];
        for(iCol = 0; iCol < nCol; iCol++) {
            int nHitCount = aPhraseinfo[3 * iCol];
            int nGlobalHitCount = aPhraseinfo[3 * iCol + 1];
            double weight = defaultWeight;
            if(nHitCount > 0) {
                score += ((double)nHitCount / (double)nGlobalHitCount) * weight;
            }
        }
    }
    
    return score;
}
