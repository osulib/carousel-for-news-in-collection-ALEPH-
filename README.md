# Description
Web carousel with book covers selected from Aleph records and downloaded from service [obalkyknih.cz](https://www.obalkyknih.cz). Can be inserted to any webpage, OPAC or presented independently on a screen in library. You can define its content, size, speed. The covers have links to your OPAC and navigation buttons (stop,play,move) are added too.

As input, you can define CCL query run over records to be selected or create a file with selected system numbers of BIB records. Batch back script intended for scheduled execution will:
1. retrieve the records (if input is CCL query, using Aleph procedure ret-03)
2. export Marcxml records (using Aleph procedure print-03) and extract book identifiers from the records: ISBN (field 020) or National Bibliography numbers (field 015)
3. Using these identifiers, it calls web service obalkyknih.cz (API 3.0) and tries to download book covers in highest available resolution.
4. Book covers are resized, the script creates carousel.xml with data about them (ID number,title,cover image name), generates dynamic part of CSS.
5. All is saved to output directory. This directory should be web available (by Apache,IIS...), contains index.html and should be thus called by http to display the carousel.

# Implementation
1. [Download](https://github.com/matyasbajger/carousel-for-news-in-collection-ALEPH-/archive/master.zip) the content of this repository to some custom script directory on your Aleph server. It must be located on Aleph server, as it runs Aleph procedures (ret-03, print-03) to retrieve records. The server IP must be also registered at [www.obalkyknih.cz](http://www.obalkyknih.cz/) to access API from its backend servers (cache.obalkyknih.cz etc.).

2. Compile java code by running 
`./make`
in this directory

3. Set configuration by editing the file `config.ini`. Here you set your BIB base, max. amount of records, size of covers (max. width is 510px as returned by obalkyknih.cz), amount of covers visible in carousel (carousel width), timing (time of sliding between covers and time delay between sliding - when carousel stops). You must also define link to your OPAC that is attached to the covers (user can access the catalogue by tapping/clicking them).
More detailed description of these parameters is in the file `config.ini`.

4. Determine the destination directory for carousel. On common Aleph server it could be `$httpd_root/htdocs/carousel/` or alike. This directory will be filled by batch back script and will contain: index.html (basic, static html file), carouselNews.css (partly static and partly dynamic CSS3), carousel.xml (data file about covers loaded by Javascript into html), jpg book covers (like 000758254.jpg, 000758813.jpg etc., where name consist of record ID (field 001) and .jpg extension).

5. Prepare CCL query for retrieving records (for example `wdr=jr201903*`) OR create a file with BIB system numbers of records for carousel. Each system number is on one line. You can use Aleph ret- procedures to create this file.
Run back batch script `./news_carousel.csh` with following arguments (parameters):
  -ccl {ccl_query} : new records will be retrieved using CCL query set after argument and space (without brackets).
     OR
  -f {filename} : record will be get from file specified after the argument and space (without brackets).
     AND
  -o {filename} : output directory for generating the carousel 

**Examples:**

`./news_carousel.csh -ccl 'wbs=ebook and wdr=201903*' -o '$httpd_root/htdocs/carousel/'`

`./news_carousel.csh -f '$data_scratch/novinky' -o '$httpd_root/htdocs/carousel/'`

**Scheduled execution** - Cannot be usually simply made by cron or Aleph job_list. The main script `news_carousel.csh` is problematic to execute by cron due to loading aleph env varibles by: $aleph_proc/def_local_env
Executing by $alephe_tab/joblist is possible, but no for complicated ccl queries with spaces, thus closed to quotes (quotes and spaces are not properly parsed by job_list).
Use the auxiliary script `news_carousel4joblist.sh`. Make this file executable and edit it - add just one line with execution of `news_carousel.csh` with all needed arguments. Than add scheduled execution of the auxiliary `news_carousel4joblist.sh` to your `$alephe_tab/job_list` (do not forget to reload job daemon by util + e + 16 9).
#
#define running news_carousel.csh including all arguments in this script and schedule running of this one in joblist


Check the output directory though web for results. Like: `http://opac.library.ufo/carousel`

## Other configuration possibilities
1. In the script directory, you can edit `carousel-static.css`, which is static part od result CSS, and `carouselNews.html`, which are static parts of generated result. By this, you can add borders, modify navigation buttons etc.
2. If you want more different carousels with different sizes, data etc., save the batch script to more directories. Set the configuration there differently and run them independently.


# Dependencies, requirements, languages
Batch script: - CSH, Java (except commonly distributed Java packages also: simple.json.org and imgscalr.org. These packs are already included in this git repository and you can download it from here.)
             - access to obalkyknih.cz API from server (IP) - IP must be registered at www.obalkyknih.cz
             - execution of Aleph procedures (ret-03, print-03), Aleph versions 18-23.
Web carousel: HTML, CSS3 (used for animation of carousel), JavaScript (for loading xml datafile and navigation buttons)

# Live demo
[https://katalog.svkos.cz/carousel/](https://katalog.svkos.cz/carousel/)
# Live at library
[https://katalog.osu.cz/](https://katalog.osu.cz/)
[https://katalog.svkos.cz/](https://katalog.svkos.cz/)

# Schema
![](https://github.com/osulib/carousel-for-news-in-collection-ALEPH-/blob/master/backend_diagram_eng.png)

# License, author
Matyas F. Bajger, 2019 @ Moravian-Silesian Research Library in Ostrava, https://www.svkos.cz

GNU Public Licence 3.0, CC BY-SA 
