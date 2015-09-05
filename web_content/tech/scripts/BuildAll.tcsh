#!/bin/tcsh -f
# build the complete svn-ready website

set me=$0:t             		# the name of this script

echo "======== ${me}: makeLists.tcsh start ========";
./makeLists.tcsh
echo "======== ${me}: makeLists.tcsh end ========";

echo; echo; echo "======== ${me}: buildRandomSutta.tcsh start ========";
./buildRandomSutta.tcsh
echo "======== ${me}: buildRandomSutta.tcsh end ========";

echo; echo; echo "======== ${me}: buildRandomArticle.tcsh start ========";
./buildRandomArticle.tcsh
echo "======== ${me}: buildRandomArticle.tcsh end ========";

# rebuild the file lists, just in case the previous scripts created some new files...
echo; echo; echo "======== ${me}: makeLists.tcsh (second pass) start ========";
./makeLists.tcsh
echo "======== ${me}: makeLists.tcsh (second pass) end ========";

echo; echo; echo "======== ${me}: BuildLegacy.tcsh start ========";
./BuildLegacy.tcsh
echo "======== ${me}: BuildLegacy.tcsh end ========";


