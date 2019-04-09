// Tool for generating xml and downloading images for Carousel News in library collection.
//    Created for Aleph LIS, but, as the input is MarcXML file, could be used with other applications too.
// 
// Reads MarcXML file as could be exported from Aleph or other system.
// Takes isbns (prospectively also other indicators) and  calls cache.obalkyknih.cz to get cover image.
// Images and xml metadata file are saved to destination directory for carousel.
//
// Arguments:	1. input file in MarcXML with book/document records 
// 		2. output directory for carousel, where cover images (jpeg) and xml file will be saved
// 		3. link to catalogue to retrieve the record by Control Number (field 001). The value shouls contain
// 		   five as-signs ('@@@@@') that are replaced by real Control Number on processsion.
// 		4. max. number of covers/books in the carousel. When reaching this limit, processing records will stop.
// 		              Total max. (default) is 100;
// 		5. (optional) url of obalkyknih.cz. Like: cache.obalkyknih.cz (default), cache2.obalkyknih.cz
//
//Dependences except common Java modules: org.json.simple
//
//Created by Matyas F. Bajger, Moravian-Silesian Research Library in Ostrava, www.svkos.cz, March 2019

import java.util.*;
import java.io.File;
import java.io.IOException;
import java.io.BufferedInputStream;
import java.net.URLEncoder;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.*;

import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;




public class CarouselNews{

    public static void main (String[] args){

    try {
       //process arguments
       String marcXmlFile = "carouselnews.xml";
       String destinationDir = "./result";
       String linkToCatalogue = "";
       int maxCovers = 100;
       int coverWidth = 150;
       String obalkyKnihFrontEnd = "cache.obalkyknih.cz";
    
       for (int i=0; i<args.length; i++) {
          if ( i==0 ) { marcXmlFile = args[i]; }   
          else if ( i==1 ) { destinationDir = args[i].replaceAll("\\s*/s*$",""); }   
          else if ( i==2 ) { linkToCatalogue = args[i]; }   
          else if ( i==3 ) { maxCovers = Integer.parseInt(args[i]); }
          else if ( i==4 ) { coverWidth = Integer.parseInt(args[i]); }
          else if ( i==5 ) { obalkyKnihFrontEnd = args[i]; }   
          }

            //get file
            DocumentBuilderFactory docBuilderFactory = DocumentBuilderFactory.newInstance();
            DocumentBuilder docBuilder = docBuilderFactory.newDocumentBuilder();
            Document doc = docBuilder.parse ( new File( marcXmlFile ) );
            doc.getDocumentElement ().normalize (); // normalize text representation

            NodeList records = doc.getElementsByTagName("record");
	          ArrayList<Book4xml> data4xml = new ArrayList<Book4xml>(); //for constructing data for carousel xml
            //loop record nodes
            int noOfOutputBooks=0;
            for(int i=0; i<records.getLength() ; i++){
                Node record = records.item(i);
                if( record.getNodeType() == Node.ELEMENT_NODE ){
 		    MarcRecord mrecord = new MarcRecord(record.getChildNodes());
		
		    String controlNumber = mrecord.getControlNumber();
		    String title = mrecord.getTitle();
		    ArrayList<String> isbns = mrecord.getIsbns();

		    System.out.println(" Processing record: "+i); 
		    System.out.println("     control number: "+controlNumber); 
		    System.out.println("     title: "+title); 
		    System.out.println("     ISBNs: "+isbns); 

		    if ( isbns.size() == 0 ) {  //loop over if there is no isbn
			continue; } 

		   //generate url to API
		   String url = "http://" + obalkyKnihFrontEnd + "/api/books?multi=";
		   String url2 = "";
                   for ( int j=0; j<isbns.size(); j++ ) {
		      String isbnx = isbns.get(j).toString();
		      if ( ! isbnx.isEmpty() ) {
   			 if ( url2.isEmpty() ) { url2 = "{\"isbn\":\"" + isbnx + "\"}"; }
			 else { url2 += ",{\"isbn\":\"" + isbnx + "\"}"; }
			 }
		      }
		   url2 = URLEncoder.encode( "["+url2+"]", "UTF-8");;
	           //call 
		   GetURL callAPI = new GetURL ( url+url2 );
		   String TXTresponse = callAPI.call();

		   JSONParser jsonParser = new JSONParser();
		   JSONArray jsonResponse = (JSONArray) jsonParser.parse(TXTresponse);

		   Iterator<?> j = jsonResponse.iterator();
		   while (j.hasNext()) {
		      JSONObject obalkyBook = (JSONObject) j.next();
		      String coverURL = (String)obalkyBook.get("cover_preview510_url");

		      System.out.println("coverURL is "+coverURL);

		      if ( coverURL != null ) {  if ( !coverURL.isEmpty() ) {
			 
			 //download files to destnation directory
			 coverURL = coverURL.replaceFirst("^https:","http:");  //BUG - do not use secure connection - it would need importing certificate to java keystore
			 String imageFile = controlNumber + ".jpg";
			 String imageFileFull = destinationDir + "/" + controlNumber + ".jpg";
			 SaveImageFromUrl saveImg = new SaveImageFromUrl ( coverURL, imageFileFull, coverWidth );		 
			 saveImg.saveImage();
			 //add values to object for xml
			 String linkToCat = linkToCatalogue.replace("@@@@@",controlNumber);

			 Book4xml book4xml = new Book4xml();

		  	 book4xml.addx(controlNumber,title,imageFile,linkToCat);


			 data4xml.add(book4xml);

			 noOfOutputBooks++;

			 break; //break loop if cover is found - avoid adding duplicate covers if json response icludes more books
        
		         } }
		      }
		   if ( noOfOutputBooks > maxCovers ) { break; } //if max. no of covers in carousel has reached
        	   } //end of loop over marcxml

          //write xml
          writeXml ( data4xml, destinationDir + "/carousel.xml");

 	  } //end of try



        }catch (SAXParseException err) {
        System.out.println ("** Parsing error" + ", line " + err.getLineNumber () + ", uri " + err.getSystemId ());
        System.out.println(" " + err.getMessage ());

        }catch (SAXException e) {
        Exception x = e.getException ();
        ((x == null) ? e : x).printStackTrace ();

        }catch (Throwable t) {
        t.printStackTrace ();
        }
        //System.exit (0);
        
    }//end of main
    
    //function to check integer (for arguments)
    private static boolean IsInteger(String str) {
	try { Integer.parseInt(str); return true; }
        catch(NumberFormatException nfe) { return false; }
        }
    
    //function to write output xml file
    public static void writeXml (ArrayList<Book4xml> data, String xmlFilePath) {
 
     try {
	DocumentBuilderFactory documentFactory = DocumentBuilderFactory.newInstance();
	DocumentBuilder documentBuilder = documentFactory.newDocumentBuilder();
	Document document = documentBuilder.newDocument();
 
	// root element
	System.out.println ("Generating xml file for output...");
	Element root = document.createElement("carousel");
	document.appendChild(root);
 
	//loop over arraylist and add elements
	for (int i=0; i<data.size(); i++) {
	   Element book = document.createElement("book");
	   root.appendChild(book);
	   Element id = document.createElement("idNumber");
           id.appendChild(document.createTextNode( data.get(i).id ) );
           book.appendChild(id); 

	   Element title = document.createElement("title");
           title.appendChild(document.createTextNode( data.get(i).title ) );
           book.appendChild(title); 

	   Element imageFileName = document.createElement("imageFileName");
           imageFileName.appendChild(document.createTextNode( data.get(i).imageFileName ) );
           book.appendChild(imageFileName); 

	   Element linkUrl = document.createElement("linkUrl");
           linkUrl.appendChild(document.createTextNode( data.get(i).linkUrl ) );
           book.appendChild(linkUrl); 

	   } 
            // set an attribute 
            //Attr attr = document.createAttribute("id");
            //attr.setValue("10");
           // book.setAttributeNode(attr);
            //you can also use book.setAttribute("id", "1") for this
 
 
            // create the xml file
            //transform the DOM Object to an XML File
             System.out.println ("Writing xml file "+xmlFilePath);
            TransformerFactory transformerFactory = TransformerFactory.newInstance();
            Transformer transformer = transformerFactory.newTransformer();
            DOMSource domSource = new DOMSource(document);
            StreamResult streamResult = new StreamResult(new File(xmlFilePath));
 
            // If you use
            // StreamResult result = new StreamResult(System.out);
            // the output will be pushed to the standard output ...
            // You can use that for debugging 
 
            transformer.transform(domSource, streamResult);
 
            System.out.println("Done creating XML File");
 
        } catch (ParserConfigurationException pce) {
            pce.printStackTrace();
        } catch (TransformerException tfe) {
            tfe.printStackTrace();
        }
    }


}



