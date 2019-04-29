#!/bin/csh -f

#Back batch script for generating web Carousel News from Aleph using book covers from obalkyknih.cz
#Arguments:
#  -ccl {ccl_query} : new records will be retrieved using CCL query set after argument and space (vithout brackets).
#  -f {filename} : record will be get from file specified after the argument and space (vithout brackets).
#  -o {filename} : output directory for generating the carousel 
#			it will contain html, css, xml (metadata) and more jpeg (book covers)
#
#Created by Matyas F. Bajger, Moravian-Silesian Research Library in Ostrava www.svkos.cz, 2019

 


echo START `date` ;
source $aleph_proc/def_local_env ;
#change to script directory
set scriptdir = `dirname $0`
set abs_scriptdir = `cd $scriptdir && pwd`
cd $abs_scriptdir
#load initial parameters
source config.ini
#get command-line arguments
set searchMode=''; #ccl or file
set searchInput=''; #ccl query or file name
set outputDir='';
set lastArgv='';
foreach a ($argv)
   set a2 = `echo "$a" | sed 's/^-*//'`
   switch ($a2)
      case 'ccl':
	 set searchMode = 'ccl';
         set lastArgv = 'ccl';
	 breaksw;
      case 'f':
	 set searchMode = 'f';
         set lastArgv = 'f';
	 breaksw;
      case 'file':
	 set searchMode = 'f';
         set lastArgv = 'f';
	 breaksw;
      case 'o':
         set lastArgv = 'o';
	 breaksw;
      case 'output':
         set lastArgv = 'o';
	 breaksw;
      case 'h':
         goto help;
	 breaksw;
      case 'help':
         goto help;
	 breaksw;
      default:
	 if ( "$lastArgv" == 'ccl' || "$lastArgv" == 'f' ) then
	    set searchInput = $a;
	 else if ( "$lastArgv" == 'o' ) then
	    set outputDir = $a;
	 endif
	 set lastArgv = '';
	 breaksw;
   endsw
end

#arguments check
if ( "$searchMode" == '' ) then
   printf "Error - no search mode to reterieve new records specified!\nUse arguments -f or -ccl. Run with -h or --help to see more.\n" 
   exit 1
endif
if ( "$outputDir" == '' ) then
   printf "Error - no output directory specified!\nSet in using argument -o. Run with -h or --help to see more.\n" 
   exit 1
endif
if ( ! -d "$outputDir"i ) then
   printf "Output directory $outputDir does not exist. Going to create it.\n\n"
   mkdir "$outputDir"
endif
rm -f $outputDir/*

set bibBaseLower = `echo $bibBase | aleph_tr -l`;
set bibBase = `echo $bibBase | aleph_tr -u`;

# input from file
if ( "$searchMode" == 'f' ) then
   if ( ! -f $searchInput ) then
      printf "Error - Input file with sysnos $searchInput not found!\nexiting...\n"
      exit 1
   endif
   sed 's/\s//g' "$searchInput" | awk '{print substr($0,1,9);}' | sed 's/$/@/' | sed "s/@/$bibBase/" >$alephe_scratch/carouselnews.sys
   echo "There were `grep $ -c $alephe_scratch/carouselnews.sys` records found and prepared for procession"
#run ccl query using p_ret_03
else if ( "$searchMode" == 'ccl' ) then
   if ( $searchInput == '' ) then
      printf "Error - you have specified -ccl mode, but no CCL query set after the -ccl argument. Run with -h or --help to see more.\nexiting...\n"
      exit 1
   endif
   printf "\nRetrieving records using p_ret_03 for CCL query: $searchInput\n\n\n"
   csh -f $aleph_proc/p_ret_03 "$bibBase,carouselnews.sys,$searchInput"
   if ( ! -f $alephe_scratch/carouselnews.sys ) then
      printf "Error - no output file from p_ret_03 found, something went wrong.\nexiting...\n";
      exit 1
   endif
   if ( -z $alephe_scratch/carouselnews.sys ) then
      printf "Notice - no records (nothing) found for the CCL query: $searchInput\n\n Nothing to do, exiting...\n";
      exit 0
   endif
else
  printf "Error - wrong search mode spefified. You must choose read from file or ccl query. Run this with -h or --help to see more.\nexiting...\n"
  exit 1
endif

#retrieve records in marcxml using p_print_03
printf "\nExporting records - running p_print_03...\n\n"
csh -f $aleph_proc/p_print_03 "MVK01,carouselnews.sys,ALL,,,,,,,,carouselnews.xml,X2,,,,N,"
#check results
if ( ! -f "$alephe_dev/$bibBaseLower/scratch/carouselnews.xml" ) then
  printf "Error - output file from export (p_print_03) $alephe_dev/$bibBaseLower/scratch/carouselnews.xml not found. Something went wrong\nexiting...\n"
  exit 1
endif   
if ( -z "$alephe_dev/$bibBaseLower/scratch/carouselnews.xml" ) then
  printf "Error - output file from export (p_print_03) $alephe_dev/$bibBaseLower/scratch/carouselnews.xml has zero size. Something went wrong\nexiting...\n"
  exit 1
endif   

#choose obalkyknih.cz frontend
set obalkyKnihFrontendsArray = ( `echo $obalkyKnihFrontends` );
foreach url ( $obalkyKnihFrontendsArray )
   set check_response=`curl -s "http://$url/api/runtime/alive" --max-time 10` 
   if ( `echo "$check_response" | sed 's/ //g' | awk '{print toupper($0);}'` == 'ALIVE' ) then
      set obalkyKnihFrontend=$url;
      break
   endif
end


#parse results and get obalkyknih.cz

java CarouselNews "$alephe_dev/$bibBaseLower/scratch/carouselnews.xml" "$outputDir" "$linkToCatalogue" $maxNoOfTitles $coverWidth "$obalkyKnihFrontend"




#check java return code
if ( $status != 0 ) then
   printf "\n\nERROR - something went wrong in processing Java, see output above.\n"
   echo "exiting ..."
   exit 1
endif

#check java output files
if ( ! -f "$outputDir/carousel.xml" ) then
  printf "Error - java output $outputDir/carousel.xml - metadata file NOT FOUND. Something went wrong\nexiting...\n"
  exit 1
endif
#this does not work:
#if ( `ls -l "$outputDir/*.jpg" | grep $ -c` == 0 ) then
#  printf "Error - No downloaded book covers found at $outputDir/*.jpg. Something went wrong\nexiting...\n"
#  exit 1
#endif

#generate dynamic css and move css to $outputDir
set cssFile="$outputDir/carouselNews.css"


printf "\nGenerating CSS ...\n";
set noOfBooks=`grep '<\s*book\s*>' $outputDir/carousel.xml -o -i | wc -l` #number of books/covers in carousel

echo '/* dynamic moving of element content */' >$cssFile
echo '@keyframes carousel {' >>$cssFile
set i = 1;
set noOfBooksx=$noOfBooks; 
set DelayTimePercent = `echo 'printf ( "%.5f", 100 / '$noOfBooks' * ( '$delayTime' / ( '$delayTime' + '$slidingTime' ) ) )' | perl`
while ( $i <= $noOfBooksx )
   set percentsOfTime = `echo 'printf ("%.2f", ( 100 / '$noOfBooks' ) * ( '$i' - 1 ) )' | perl`
   set percentsOfTime2 = `echo 'printf ("%.2f", '$percentsOfTime' + '$DelayTimePercent' )' | perl`
   set coverPosition = `echo  'printf ("%.0f",  ( '$carouselWidth' - '$noOfBooks' + '$i' - 1 ) * ( '$coverWidth' * 1.2  ) )' | perl`
   echo "   $percentsOfTime""% {margin-left: $coverPosition""px;}" >>$cssFile
   echo "   $percentsOfTime2""% {margin-left: $coverPosition""px;}" >>$cssFile
   @ i++
end
printf "     }\n\n" >>$cssFile

echo '.bookCarousel {' >>$cssFile
set elementWidth = `echo 'printf ("%.0f", '$carouselWidth' * '$coverWidth' * 1.2 )' | perl`
set elementHeight = `echo 'printf ("%.0f", '$coverWidth' * 1.7  )' | perl`
echo "   width: $elementWidth""px;" >>$cssFile
echo "   max-width: $elementWidth""px;" >>$cssFile
echo "   height: $elementHeight""px;" >>$cssFile
echo "   max-height: $elementHeight""px;" >>$cssFile
printf "     }\n\n" >>$cssFile

echo '.bookCarousel div {' >>$cssFile
set totalTime = `echo 'printf ("%.0f", '$noOfBooks' * ( '$slidingTime' + '$delayTime' ) )' | perl`
echo "   animation: carousel $totalTime""s infinite;  /* this works also in IE11*/" >>$cssFile
echo '  /*animation: carousel var(--totalTime) infinite; # this does not work in IE11*/' >>$cssFile
echo '  /*animation: carousel calc( 20s * 2 * 3 ) infinite;  #this calc() does not work in IE 11 */' >>$cssFile
set positionTop  = `echo 'printf ("%.0f", 0 - ( '$coverWidth' * 0.46 ) )' | perl` 
echo "  position: relative; top: $positionTop""px;" >>$cssFile 
printf "     }\n\n" >>$cssFile

echo '.bookCarousel article {' >>$cssFile
set widthWithMargins = `echo 'printf ("%.0f", '$coverWidth' * 1.2 )' | perl`
echo "   width: $widthWithMargins""px;" >>$cssFile 
printf "     }\n\n" >>$cssFile

echo '.carouselNavigationBar {' >>$cssFile
echo "   width: $elementWidth""px;" >>$cssFile
set navigationBarFontSize = `echo 'printf ("%.1f", '$elementWidth' * 0.12 )' | perl`
echo "   font-size: $navigationBarFontSize""px;" >>$cssFile
printf "     }\n\n" >>$cssFile

echo '.bookCarousel article img {' >>$cssFile
echo "   width: $coverWidth""px" >>$cssFile
printf "     }\n\n\n" >>$cssFile


cat carousel-static.css >>$cssFile

printf "\nFinally copying html file to output directory $outputDir\n"
yes | cp -fv carouselNews.html $outputDir/index.html


echo "the END" `date`
exit 0


help:
echo "Back batch script for generating web Carousel News from Aleph using book covers from obalkyknih.cz"; echo;
echo "Arguments:"
echo '  -ccl {ccl_query} : new records will be retrieved using CCL query set after the argument and space (vithout brackets).'
echo '  -f {filename} : record will be get from file specified after the argument and space (vithout brackets).'
echo '  -o {filename} : output directory for generating the carousel '
echo '                    it will contain html, css, xml (metadata) and more jpeg (book covers).'
printf "Example:  ./news_carousel.csh -ccl 'wdr=2019' -o $httpd_root/htdocs/news_carousel.html\n\n"; 
exit 0



