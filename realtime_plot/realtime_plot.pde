//////////////////////////////////////////////////////////////////////////////////////////
//
//   Desktop GUI for real time plot searil data
//
//   Modified by: Jinbuhm Kim (jinbuhm.kim@gmail.com)
//
//   Poke "protocentral_openview" and modified it leaving only the minimum functionality.
//
//   This software is licensed under the MIT License(http://opensource.org/licenses/MIT). 
//   
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
//   NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
//   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
//   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
//   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
/////////////////////////////////////////////////////////////////////////////////////////

import processing.serial.*;
import grafica.*;

// Java Swing Package For prompting message
import java.awt.*;
import javax.swing.*;
import static javax.swing.JOptionPane.*;

// File Packages to record the data into a text file
import javax.swing.JFileChooser;
import java.io.FileWriter;
import java.io.BufferedWriter;

// Date Format
import java.util.*;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

// General Java Package
import java.math.*;
import controlP5.*;

ControlP5 cp5;
PImage logo;

String selectedTest;

int windowSize = 6 * 128;                                            // Total Size of the buffer
int arrayIndex1=0;
int arrayIndex2=0;
int arrayIndex3=0;

// float[] xdata = new float[windowSize];
float[] ch1Data = new float[windowSize];
float[] ch2Data = new float[windowSize];
float[] ch3Data = new float[windowSize];

boolean startPlot = false;
GPlot plot1, plot2, plot3;

/************** File Related Variables **********************/
boolean logging = false;                                // Variable to check whether to record the data or not
FileWriter output;                                      // In-built writer class object to write the data to file
JFileChooser jFileChooser;                              // Helps to choose particular folder to save the file
Date date;                                              // Variables to record the date related values                              
BufferedWriter bufferedWriter;
DateFormat dateFormat;

/************** Port Related Variables **********************/
Serial port = null;                                     // Oject for communicating via serial port
float inByte;

String selectedPort;                                    // Holds the selected port number

int totalPlotsHeight=0;
int totalPlotsWidth=0;
int heightHeader=100;

Textlabel lblSelectedDevice;
Textlabel lblComputedVal1;
Textlabel lblComputedVal2;

final static String ICON  = "icon_logo.jpg";

void initBuffer()
{
  for (int i=0; i<windowSize; i++) 
  {
    //time = time + 1;
    //xdata[i]=time;
    ch1Data[i] = 0;
    ch2Data[i] = 0;
    ch3Data[i] = 0;    
  }
}

public void setup() 
{  
  GPointsArray pointsPPG = new GPointsArray(windowSize);
  GPointsArray pointsEEG = new GPointsArray(windowSize);
  GPointsArray pointsAccel = new GPointsArray(windowSize);

  size(1024, 768, JAVA2D);
  //fullScreen();
   
  heightHeader = 100;
  println("Height:"+ height);

  totalPlotsHeight = height - heightHeader;
  
  makeGUI();
  surface.setTitle("Real Time Plot");
  PImage icon = loadImage("icon_logo.png");
  surface.setIcon(icon);
  
  plot1 = new GPlot(this);
  plot1.setPos(20,60);
  plot1.setDim(width - 40, (totalPlotsHeight/3) - 10);
  plot1.setBgColor(0);
  plot1.setBoxBgColor(0);
  plot1.setLineColor(color(0, 255, 0));
  plot1.setLineWidth(3);
  plot1.setMar(0,0,0,0);
  
  plot2 = new GPlot(this);
  plot2.setPos(20,(totalPlotsHeight/3+60));
  plot2.setDim(width-40, (totalPlotsHeight/3)-10);
  plot2.setBgColor(0);
  plot2.setBoxBgColor(0);
  plot2.setLineColor(color(255, 255, 0));
  plot2.setLineWidth(3);
  plot2.setMar(0,0,0,0);

  plot3 = new GPlot(this);
  plot3.setPos(20,(totalPlotsHeight/3+totalPlotsHeight/3+60));
  plot3.setDim(width-40, (totalPlotsHeight/3)-10);
  plot3.setBgColor(0);
  plot3.setBoxBgColor(0);
  plot3.setLineColor(color(0,0,255));
  plot3.setLineWidth(3);
  plot3.setMar(0,0,0,0);

  for (int i = 0; i < windowSize; i++) 
  {
    pointsEEG.add(i, 0);
    pointsPPG.add(i, 0);
    pointsAccel.add(i, 0); 

  }

  plot1.setPoints(pointsEEG);
  plot2.setPoints(pointsPPG);
  plot3.setPoints(pointsAccel);

  initBuffer();

}


void changeAppIcon(PImage img) {
  final PGraphics pg = createGraphics(16, 16, JAVA2D);

  pg.beginDraw();
  pg.image(img, 0, 0, 16, 16);
  pg.endDraw();

}


public void makeGUI()
{  
  cp5 = new ControlP5(this);

  cp5.addToggle("toggleONOFF")
    .setPosition(width-225,10)
    .setSize(100,40)
    .setValue(false)
    .setColorBackground(color(0,255,0))
    .setColorActive(color(255,0,0))
    .setCaptionLabel("START")
    .setColorLabel(0) 
    .getCaptionLabel()
    .setFont(createFont("Arial",15))
    .toUpperCase(false)
    .align(ControlP5.CENTER,ControlP5.CENTER)
    ;

  cp5.addButton("Record")
    .setValue(0)
    .setPosition(width-110,10)
    .setSize(100,40)
    .setFont(createFont("Arial",15))
    .addCallback(new CallbackListener() {
        public void controlEvent(CallbackEvent event) {
          if (event.getAction() == ControlP5.ACTION_RELEASED) 
          {
            RecordData();
            //cp5.remove(event.getController().getName());
          }
        }
      } 
    );
        
  cp5.addScrollableList("portName")
      .setPosition(20, 10)
      .setLabel("Select Port")
      .setSize(250, 400)
      .setFont(createFont("Arial",12))
      .setBarHeight(40)
      .setOpen(false)
      .setItemHeight(40)      
      // .addItems(port.list())
      .setType(ScrollableList.DROPDOWN) // currently supported DROPDOWN and LIST
      .addCallback(new CallbackListener() {
          public void controlEvent(CallbackEvent event) {
            if (event.getAction() == ControlP5.ACTION_PRESSED) 
            {
                cp5.get(ScrollableList.class, "portName").setItems(port.list());
            }
          }
        } 
      );

  cp5.addScrollableList("testIndex")
   .setPosition(275, 10)
   .setSize(150, 400)
   .setFont(createFont("Arial",12))
   .setBarHeight(40)
   .setItemHeight(40)
   .setOpen(false)    
   .addItem("EEG","1")
   .addItem("PPG","2")
   .addItem("Accelerometer","3")
   .setType(ScrollableList.DROPDOWN);

  cp5.addButton("logo")
  .setPosition(20,height-40)
  .setImages(loadImage("bottom_logo.png"), loadImage("bottom_logo.png"), loadImage("bottom_logo.png"))
  .updateSize();    

  lblSelectedDevice = cp5.addTextlabel("lblSelectedDevice")
  .setText("")
  .setPosition(250,height-30)
  .setColorValue(color(255,255,255))
  .setFont(createFont("verdana", 14));
   
}

void displayPortStatus()
{
    lblSelectedDevice.setText("Selected port: " + selectedPort);
}

void portName(int n) 
{
  println(n, cp5.get(ScrollableList.class, "portName").getItem(n));
  selectedPort = cp5.get(ScrollableList.class, "portName").getItem(n).get("name").toString();
  displayPortStatus();  
}

void toggleONOFF(boolean onoff) {
  if(onoff == true) {
      startSerial(selectedPort, 230400);
      cp5.get(Toggle.class, "toggleONOFF").setCaptionLabel("STOP");
      cp5.get(ScrollableList.class, "portName").lock();

      initBuffer();

      // Start command
      println("Start command");
      if (selectedTest == "EEG") {
          port.write('E');
      }else if (selectedTest == "PPG") {
          port.write('P');
      }else if (selectedTest == "Accelerometer") {
          port.write('A');
      }
  } else {
      if(port != null){
        // Stop command
        println("Stop command");      
        port.write('T');      

        stopSerial();
        cp5.get(Toggle.class, "toggleONOFF").setCaptionLabel("START");
        cp5.get(ScrollableList.class, "portName").unlock();
      }
  }
}

void testIndex(int n) 
{
  println(n, cp5.get(ScrollableList.class, "testIndex").getItem(n));
  selectedTest = cp5.get(ScrollableList.class, "testIndex").getItem(n).get("name").toString();
}


public void draw() 
{
  //background(0);
  background(19,75,102);

  GPointsArray pointsPlot1 = new GPointsArray(windowSize);
  GPointsArray pointsPlot2 = new GPointsArray(windowSize);
  GPointsArray pointsPlot3 = new GPointsArray(windowSize);

  if (startPlot)                             // If the condition is true, then the plotting is done
  {
    for(int i=0; i<windowSize;i++)
    {    
      pointsPlot1.add(i,ch1Data[i]);
      pointsPlot2.add(i,ch2Data[i]); 
      pointsPlot3.add(i,ch3Data[i]);  
    }
  } 
  
  plot1.setPoints(pointsPlot1);
  plot2.setPoints(pointsPlot2);
  plot3.setPoints(pointsPlot3);
  
  plot1.beginDraw();
  plot1.drawBackground();
  plot1.drawLines();
  plot1.endDraw();
  
  plot2.beginDraw();
  plot2.drawBackground();
  plot2.drawLines();
  plot2.endDraw();

  plot3.beginDraw();
  plot3.drawBackground();
  plot3.drawLines();
  plot3.endDraw();
}

public void CloseApp() 
{
  int dialogResult = JOptionPane.showConfirmDialog (null, "Would You Like to Close The Application?");
  if (dialogResult == JOptionPane.YES_OPTION) {
    try
    {
      //Runtime runtime = Runtime.getRuntime();
      //Process proc = runtime.exec("sudo shutdown -h now");
      System.exit(0);
    }
    catch(Exception e)
    {
      exit();
    }
  } 
}

public void RecordData()
{
    try
  {
    jFileChooser = new JFileChooser();
    jFileChooser.setSelectedFile(new File("log.csv"));
    jFileChooser.showSaveDialog(null);
    String filePath = jFileChooser.getSelectedFile()+"";

    if ((filePath.equals("log.txt"))||(filePath.equals("null")))
    {

    } else
    {    
      logging = true;
      date = new Date();
      output = new FileWriter(jFileChooser.getSelectedFile(), true);
      bufferedWriter = new BufferedWriter(output);
      bufferedWriter.write(date.toString()+"");
      bufferedWriter.newLine();
      bufferedWriter.write("TimeStamp,ECG,PPG");
      bufferedWriter.newLine();
    }
  }
  catch(Exception e)
  {
    println("File Not Found");
  }
}

void startSerial(String startPortName, int baud)
{
  try
  {
      port = new Serial(this, startPortName, baud);
      port.clear();
      startPlot = true;
  }
  catch(Exception e)
  {
    showMessageDialog(null, "Port not available", "Error", ERROR_MESSAGE);
    System.exit (0);
  }
}

void stopSerial()
{
  try
  {
      port.clear();
      port.stop();
      startPlot = false;
  }
  catch(Exception e)
  {
    showMessageDialog(null, "Port not available", "Alert", ERROR_MESSAGE);
    System.exit (0);
  }
}


void serialEvent (Serial myPort)
{
  float accel_x, accel_y, accel_z;
  String inString = myPort.readStringUntil('\n');

  if (inString != null) {
    inString = trim(inString);  // trim off whitespaces.

    if (selectedTest == "Accelerometer") {
      String[] q = splitTokens(inString, ", ");

      accel_x = float(q[0]);
      accel_y = float(q[1]);
      accel_z = float(q[2]);

      ch1Data[arrayIndex3] = map(accel_x, 0, windowSize, 0, height);
      ch2Data[arrayIndex3] = map(accel_y, 0, windowSize, 0, height);
      ch3Data[arrayIndex3] = map(accel_z, 0, windowSize, 0, height);            

      // ch1Data[arrayIndex3] = accel_x;
      // ch2Data[arrayIndex3] = accel_y;
      // ch3Data[arrayIndex3] = accel_z;

      arrayIndex3++;
      if (arrayIndex3 == windowSize)
      {  
        arrayIndex3 = 0;
      }
    }else {
      inByte = float(inString);   // convert to a number.
      inByte = map(inByte, 0, windowSize, 0, height); //map to the screen height.
    }
  }

    if (selectedTest == "EEG") {
      ch1Data[arrayIndex1] = inByte;
      arrayIndex1++;
      if (arrayIndex1 == windowSize)
      {  
        arrayIndex1 = 0;
      }
    }else if (selectedTest == "PPG") {
      ch2Data[arrayIndex2] = inByte;
      arrayIndex2++;
      if (arrayIndex2 == windowSize)
      {  
        arrayIndex2 = 0;
      }
  }
}
