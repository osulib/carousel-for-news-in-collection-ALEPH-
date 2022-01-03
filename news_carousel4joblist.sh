#!/bin/bash
#
# Script for scheduled runnning of news_carousel.csh
# news_carousel.csh is problematic to execute by cron due to loading aleph env varibles by: $aleph_proc/def_local_env
# Executing by $alephe_tab/joblist is possible, but no for complicated ccl queries.
#             Parsing arguments in joblist does not respect quotes. Like 'ty vole' is parsed as two arguments ['ty] and [vole']
#
#define running news_carousel.csh including all arguments in this script and schedule running of this one in joblist
#
#Example for retrieving records from last week:
#/news_carousel.csh -ccl "wdr=new`date '+%Y%m%d' --date='7 days ago'`->new`date '+%Y%m%d'`" -o /exlibris/aleph/u23_1/alephe/apache/htdocs/carousel

#Sarka chctela zvhodit Bookport, po vetsim importu 20201009 tam zla sama beletrie
#o vanocich 2020 byl vystupni soubor praydny, bo nebyly zadne novinky. Pridany kontroly vystupu a pokud je praydnz, lhuta & dnu se prodlouzi na !$ resp. @! dnu. 20210107 Matyas Bajger

outputDir='/exlibris/aleph/u23_1/alephe/apache/htdocs/carousel'
/exlibris/aleph/matyas/carousel/news_carousel.csh -ccl "wdr=`date '+%Y%m%d' --date='7 days ago'`->`date '+%Y%m%d'` not wps=Ve zpracovani not wbs=bookp*" -o $outputDir
resultCount=0
if [ -s $outputDir/carousel.xml]; then
   resultCount=`xmllint --xpath 'count(//book)' $outputDir/carousel.xml`
fi
if [ $resultCount -lt 8 ]; then #try 14 days
   echo WARNING - LESS THAN 8 RESULT FOUND, SEEKING 14 DAYS BACK
   /exlibris/aleph/matyas/carousel/news_carousel.csh -ccl "wdr=`date '+%Y%m%d' --date='14 days ago'`->`date '+%Y%m%d'` not wps=Ve zpracovani not wbs=bookp*" -o $outputDir
   if [ -s $outputDir/carousel.xml]; then
      resultCount=`xmllint --xpath 'count(//book)' $outputDir/carousel.xml`
   fi
   if [  $resultCount -lt 8 ]; then #try 21 days
      echo WARNING - LESS THAN 8 RESULT FOUND, SEEKING 21 DAYS BACK
      /exlibris/aleph/matyas/carousel/news_carousel.csh -ccl "wdr=`date '+%Y%m%d' --date='21 days ago'`->`date '+%Y%m%d'` not wps=Ve zpracovani not wbs=bookp*" -o $outputDir
      if [ -s $outputDir/carousel.xml]; then
         resultCount=`xmllint --xpath 'count(//book)' $outputDir/carousel.xml`
      fi
      if [  $resultCount -lt 8 ]; then #try a month
         echo WARNING - LESS THAN 8 RESULT FOUND, SEEKING A MONTH BACK
         /exlibris/aleph/matyas/carousel/news_carousel.csh -ccl "wdr=`date '+%Y%m%d' --date='30 days ago'`->`date '+%Y%m%d'` not wps=Ve zpracovani not wbs=bookp*" -o $outputDir
      fi
   fi
fi

#/exlibris/aleph/matyas/carousel/news_carousel.csh -ccl "wdr=`date '+%Y%m%d' --date='20 days ago'`->`date '+%Y%m%d'` not wps=Ve zpracovani not wbs=bookp* not sbn=978-80-7642-664-1" -o /exlibris/aleph/u23_1/alephe/apache/htdocs/carousel
~
~
