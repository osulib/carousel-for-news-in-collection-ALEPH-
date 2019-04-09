#
# define shell used below in this makefile
#
SHELL := /bin/bash

#
# define compiler and compiler flag variables
#
JFLAGS = -g
JC = javac

#
# Clear any default targets for building .class files from .java files; we 
# will provide our own target entry to do this in this makefile.
# make has a set of default targets for different suffixes (like .c.o) 
# Currently, clearing the default for .java.class is not necessary since 
# make does not have a definition for this target, but later versions of 
# make may, so it doesn't hurt to make sure that we clear any default 
# definitions for these
#
.SUFFIXES: .java .class

#
# Here is target entry for creating .class files from .java files 
# This is a target entry that uses the suffix rule syntax:
#	DSTS:
#		rule
#  'TS' is the suffix of the target file, 'DS' is the suffix of the dependency 
#  file, and 'rule'  is the rule for building a target	
# '$*' is a built-in macro that gets the basename of the current target 
# Remember that there must be a < tab > before the command line ('rule') 
#
.java.class:
	$(JC) $(JFLAGS) $*.java


#
# CLASSES is a macro consisting of words - each one for each java source file)
# 
CLASSES = \
        org/imgscalr/Scalr.java \
        org/json/simple/ItemList.java \
        org/json/simple/JSONArray.java \
        org/json/simple/JSONAware.java \
        org/json/simple/JSONObject.java \
        org/json/simple/JSONStreamAware.java \
        org/json/simple/JSONValue.java \
        org/json/simple/parser/ContainerFactory.java \
        org/json/simple/parser/ContentHandler.java \
        org/json/simple/parser/JSONParser.java \
        org/json/simple/parser/ParseException.java \
        org/json/simple/parser/Yylex.java \
        org/json/simple/parser/Yytoken.java \
        Book4xml.java \
        GetURL.java \
        MarcRecord.java \
      	SaveImageFromUrl.java \
        CarouselNews.java \
	/

#
# the default make target entry
#
default: classes

#
# This target entry uses Suffix Replacement within a macro: 
# $(name:string1=string2)
# 	In the words in the macro named 'name' replace 'string1' with 'string2'
# Below we are replacing the suffix .java of all words in the macro CLASSES 
# with the .class suffix
#
classes: $(CLASSES:.java=.class)



#
# RM is a predefined macro in make (RM = rm -f)
#
clean:
	$(RM) *.class
