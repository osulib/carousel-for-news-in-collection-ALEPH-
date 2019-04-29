import java.awt.AlphaComposite;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import javax.imageio.ImageIO;

import org.imgscalr.*;



/**
 *  Downloads image from url, resize it and saves to destination file
 *          Arguments:     url  String,    
 *                         destination-file  String
 *                         width int  (width of the result image. Optional, if not set, image would not be resized)
 *                         height int (height of the same. Optional, if not set, the value is counted proportionaly)
 **/

public class SaveImageFromUrl {  //donwload and save image or any file from URL
					//
	public String imageUrl;
	public String destinationFile;
  public int width;
  public int height;  
	
	//constructors
	public SaveImageFromUrl (String a, String b, int x, int y) {
	    imageUrl=a;
	    destinationFile=b;
	    width=x;
	    height=y;
	    }

	public SaveImageFromUrl (String a, String b, int x) {
	    imageUrl=a;
	    destinationFile=b;
	    width=x;
	    height=0;
	    }



	public void saveImage() throws IOException {
    
    System.out.println ( "Downloading cover " + this.imageUrl + " to file " + this.destinationFile);
    //download from url
		URL url = new URL(this.imageUrl);
		InputStream is = url.openStream();
		OutputStream os = new FileOutputStream(this.destinationFile);

		byte[] b = new byte[2048];
		int length;

		while ((length = is.read(b)) != -1) {	os.write(b, 0, length);}

		is.close();
		os.close();
    
    //resize if final width is less than 200px
    if ( this.width != 0 && this.width < 200) {
        BufferedImage originalImage = ImageIO.read(new File(this.destinationFile));
	    	int type = originalImage.getType() == 0? BufferedImage.TYPE_INT_ARGB : originalImage.getType();
        if ( this.height == 0 ) { //no height as argument, get it from image
           int origHeight = originalImage.getHeight();
           int origWidth = originalImage.getWidth();
           double ratio = (double) origHeight / origWidth;
           this.height = (int) Math.round(this.width * ratio);
           }
        //BufferedImage resizedImage = resizeImage(originalImage, this.width, this.height, type); //this resize method leads to very poor result image quality
        BufferedImage resizedImage = Scalr.resize(originalImage, Scalr.Method.ULTRA_QUALITY, Scalr.Mode.FIT_TO_WIDTH, this.width, Scalr.OP_ANTIALIAS);
        ImageIO.write(resizedImage, "jpg", new File(this.destinationFile));   
       }
    
	}

  private static BufferedImage resizeImage(BufferedImage originalImage, int width, int height, int type){
	   BufferedImage resizedImage = new BufferedImage(width, height, type);
	   Graphics2D g = resizedImage.createGraphics();
	   g.drawImage(originalImage, 0, 0, width, height, null);
	   g.dispose();
		 return resizedImage;
     }
}
