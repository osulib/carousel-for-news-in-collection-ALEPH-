#!/bin/sh
#
# Script for scheduled runnning of news_carousel.csh
# news_carousel.csh is problematic to execute by cron due to loading aleph env varibles by: $aleph_proc/def_local_env
# Executing by $alephe_tab/joblist is possible, but no for complicated ccl queries.
#             Parsing arguments in joblist does not respect quotes. Like 'ty vole' is parsed as two arguments ['ty] and [vole']
#
#define running news_carousel.csh including all arguments in this script and schedule running of this one in joblist
#
#Example for retrieving records from last week:
#/path2script/news_carousel.csh -ccl "wdr=new`date '+%Y%m%d' --date='7 days ago'`->new`date '+%Y%m%d'`" -o /exlibris/aleph/u23_1/alephe/apache/htdocs/carousel
