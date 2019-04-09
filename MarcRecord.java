import java.util.*; 
import org.w3c.dom.*;

 import javax.xml.parsers.DocumentBuilderFactory;
 import javax.xml.parsers.DocumentBuilder;
 import org.xml.sax.SAXException;
 import org.xml.sax.SAXParseException;


public class MarcRecord {
   public NodeList fields;
   //constructor
   public MarcRecord (NodeList x) { 
      fields=x;
      }
   //returns values (textNodes) of subfields set in 2nd argument - string
   public String getSubfields ( NodeList subfields, String codes ) { // 1. Seznam podpoli,   2. seznam kodu podpoli k vraceni (string)
      String x="";
      for ( int i=0; i<subfields.getLength(); i++) {
         Element subfieldElement = (Element)subfields.item(i);
         String subfCode = subfieldElement.getAttribute("code");
         if ( ( codes.length()==1 && codes.equals(subfCode) ) || ( codes.length()>1 && codes.split( subfCode ).length > 1 ) ) { //cannot use matches() - this matches whole strinh
            x +=  subfieldElement.getTextContent() ;    
            }
         }
      return x.replaceAll("\\s*/$","");
      }   


   //get isbns from 020/a fields
   public ArrayList<String> getIsbns() {  
      ArrayList<String> x = new ArrayList<String>();
      for ( int i=0; i < fields.getLength(); i++) {
         Node fieldNode = fields.item(i);
	 if ( fieldNode.getNodeType() == Node.ELEMENT_NODE){
            Element fieldElement = (Element)fieldNode;
            if ( fieldElement.getAttribute("tag").equals("020") ) {
               String isbn = getSubfields ( fieldElement.getElementsByTagName("subfield"), "a" );
               if ( !isbn.isEmpty() && isbn != null ) { x.add(isbn.replaceAll("\\s.*$","") ); }
	       }
            }
         }
      return x;
      }
   
   //get Control Number from 001 fields
   public String getControlNumber() {  
      String x = new String();
      for ( int i=0; i < fields.getLength(); i++) {
         Node fieldNode = fields.item(i);
	 if ( fieldNode.getNodeType() == Node.ELEMENT_NODE){
            Element fieldElement = (Element)fieldNode;
            if ( fieldElement.getAttribute("tag").equals("001") ) {
	       x = fieldElement.getTextContent() ;
	       break; //just one 001 field is possible
	       }
            }
         }
      return x;
      }



   //get title  from field 245, subfields abpn
   public String getTitle() {  
      String x = new String();
      for ( int i=0; i < fields.getLength(); i++) {
         Node fieldNode = fields.item(i);
	 if ( fieldNode.getNodeType() == Node.ELEMENT_NODE){
            Element fieldElement = (Element)fieldNode;
            if ( fieldElement.getAttribute("tag").equals("245") ) {
               x = getSubfields ( fieldElement.getElementsByTagName("subfield"), "abnp" );

               break; //just one 245 field is possible
	       }
            }
         }
      return x;
      }
   
  }
