import java.util.*; 
import org.w3c.dom.*;
import java.lang.Object;
import java.net.MalformedURLException; 
import java.net.URL; 
import java.net.URLConnection;
import java.net.HttpURLConnection ;
import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;


public class GetURL {
   public String url;
   //constructor
   public GetURL ( String x ) {
       url = x;
       } 

   public String call()  throws MalformedURLException, java.io.IOException {

		
//debug
System.out.println("DEBUG CAll url "+url);

		URL obj = new URL(url);
		HttpURLConnection con = (HttpURLConnection) obj.openConnection();

		con.setRequestMethod("GET");

//		con.setRequestProperty("User-Agent", USER_AGENT);

		int responseCode = con.getResponseCode();
		System.out.println("\nSending 'GET' request to URL : " + url);
		System.out.println("Response Code : " + responseCode);

		BufferedReader in = new BufferedReader(
		        new InputStreamReader(con.getInputStream()));
		String inputLine;
		StringBuffer response = new StringBuffer();

		while ((inputLine = in.readLine()) != null) {
			response.append(inputLine);
		}
		in.close();

		System.out.println(response.toString());


      return response.toString();
      }

   }

