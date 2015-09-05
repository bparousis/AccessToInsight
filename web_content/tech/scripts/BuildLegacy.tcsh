#!/bin/tcsh -f
# Build the static version of the website and zip it
set > ~/tmp/set.0.tmp
set me=$0:t             		# the name of this script

set cmd='echo'

set theVersionDate 		= `date "+%A %e %b %Y"`	# human-readable date of this version
set theVersion 			= `date "+%Y.%m.%d.%H"`	# version no. used in file names, etc.
set thePrefixName 		= "ati-legacy-"			# prefix for the zip file
set theZipFileName 		= ${thePrefixName}${theVersion}.zip		# a file name containing the version no. (e.g., "ati-legacy-2013.12.01.18.zip")
set theTmpDir 			= "~/tmp"	#workspace

# path to the script that creates the static version of the site
set staticify 			= 'static.tcsh'

# set some paths, relative to the top of the site
set relPathToDownloadDir	= "tech/download"
set relPathToBulkDir		= "tech/download/bulk"

# parameters for the dynamic site
set serverURL 			= "http://ati"			# domain that will be spidered by wget 
set homeDir_dynamic 	= "~/Sites/ati.svn"		# abs path to the home dir of the website to be static-ified and zipped
set downloadDir_dynamic	= "${homeDir_dynamic}/${relPathToDownloadDir}"		#abs path to the "download" directory (dynamic)
set installDir_dynamic 	= "${downloadDir_dynamic}/bulk/"		# abs path to the dir where the zip file should be installed
set zipRedirector_dynamic 	= "${downloadDir_dynamic}/zipfile.html"	# abs path to the html file that redirects to the zip file (dynamic)
set build_kludgeFile 	= "${homeDir_dynamic}/tech/download/_wget_mode_static.tmp" # see comments in config.inc.php

# set parameters for the static site
set topDir_static 			= "~/Sites/ati.legacy.svn" 			# abs path to the svn checkout of the static site to be rebuilt
set homeDir_static 		= "${topDir_static}/ati_website/html" 	# abs path to the home dir of the static site
set downloadDir_static	= "${homeDir_static}/${relPathToDownloadDir}"		#abs path to the "download" directory (static)
set installDir_static	= "${downloadDir_static}/bulk/"	# abs path to the dir where the zip file should be installed
set zipRedirector_static = "${downloadDir_static}/zipfile.html"	# abs path to the html file that redirects to the zip file (static)
set relPathToStaticZip 	= "bulk/${theZipFileName}"		# path (relative to $zipRedirector_static) of the zip file
set htmlStart_static 	= "${topDir_static}/ati_website/start.html"	# abs path to the static site "start" page

set > ~/tmp/set.1.tmp
echo ; echo "========== Executing ${me} with the following variables: ================="; echo
diff ~/tmp/set.*.tmp | sed -e "/^[^>]/d" -e "s/^> /              /"
echo; echo "==========================="; echo; echo

#################### KLUDGE ALARM!!!! ###################
# The config.inc.php file defines the name of a file whose presence tells wget
# (and the PHP server) that we're gonna be generating static pages. 
# The content of the file is the version number of this bulk edition.
# !!! The filename defined here must match that defined in config.inc.php !!!
set OFFLINE_VERSION_FILE = "{$homeDir_dynamic}/tech/download/_OFFLINE_VERSION.txt"
echo $theVersion > $OFFLINE_VERSION_FILE
echo $theZipFileName >> $OFFLINE_VERSION_FILE
echo $theVersionDate >> $OFFLINE_VERSION_FILE
#################### KLUDGE ALARM!!!! ###################


goto Start
##############################
Usage:
cat << END_INPUT
usage: ${me}
Creates an archive of the entire site.
END_INPUT
goto ByeBye
##############################


Start:
if ($# != 0) then
	goto Usage
endif

echo "Preparing legacy archive of the website: ${theZipFileName}"

echo "Updating static mirror..."
touch $build_kludgeFile  # for communicating to the PHP server that we're generating static pages
$staticify $homeDir_dynamic $serverURL $homeDir_static
/bin/rm $build_kludgeFile # cleanup the static kludge file
echo "Static mirror is up to date."
echo 

echo -n "creating start file redirector for the static site..."
cat << END_INPUT > $htmlStart_static
<!DOCTYPE html>
<html lang=en>
<head>
<title>Redirecting...</title>
<meta charset="UTF-8">
<meta http-equiv="Refresh" content="0; URL=html/index.html">
</head>
<body style='background-color:#fff'></body>
</html>
END_INPUT

echo "done"

echo -n "creating zip archive..."
cd $topDir_static
find . -name .DS_Store -exec /bin/rm {} \; 	# expunge undesirable cruftitudinous fileage

# jtb 20130924  PDFs are now included in the offline edition
# zip -r -q $theZipFileName ati_website -x ati_website/html/cgi\* \*.pdf ati_website/html/rss\* \*.zip
zip -r -q $theZipFileName ati_website -x ati_website/html/tech/download/bulk/\*.zip \*.svn\*
cp $theZipFileName $installDir_static	# copy the zip file to the bulk folder on the static site
mv $theZipFileName $installDir_dynamic	# move the zip file to the bulk folder on the dynamic site
echo "done."

echo -n "creating the html redirect to the new archive..."
cat << END_INPUT > $zipRedirector_dynamic
<!DOCTYPE html>
<html lang=en>
<head>
<title>Redirecting...</title>
<meta charset="UTF-8">
<meta http-equiv="Refresh" content="0; URL=${relPathToStaticZip}">
</head>
<body style='background-color:#fff'></body>
</html>
END_INPUT
echo "done."


goto ByeBye;



##############################
ByeBye:

echo; echo "${me}: archive '${theZipFileName}' created and installed to both the dynamic and static sites."; echo
echo "${me}: done."
exit
