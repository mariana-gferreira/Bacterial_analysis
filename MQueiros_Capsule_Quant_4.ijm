//For Miguel Queirós @RSL@ITQB
//Made with ImageJ 1.53c
//Made by Mariana Ferreira @ITQB NOVA

macro "Cell_Capsule_Quant Action Tool - C000 T0b07C T5b07a T9b07p Tdb07s Tgb07l" {
	//Prepares work environment to run the macro
	run("Close All");
	run("Clear Results");
	close("Results");
	roiManager("reset");
	selectWindow("ROI Manager"); 
	run("Close");
	run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
	x=1000; y=250;
	call("ij.gui.WaitForUserDialog.setNextLocation",x,y);

	//Set some variables
	bin = "binary";
	running = true;
	norm = "Normalized";

	//Begin batch mode and While loop
	setBatchMode(true);
	while (running == true) {

		//Open dialogue to select file to open
		path = File.openDialog("Select image");
		run("Bio-Formats Windowless Importer", "open=[" + path + "]");
		//run("Close Fiji Console");
	
		//Confirms only one image is open, exits if more than one or none are open
		list = getList("image.titles");
		if (list.length==0)
			exit("No image windows are open");
		else if(list.length>1){
			exit("Too many image windows are open");
		}

		//Get open image dimensions, exits if it has more than 2 channels
		getDimensions(width, height, channels, slices, frames);
		if (channels!=2){
			exit("Image has the wrong number of Channels");
		}

		//Get image directory and file name
		save_dir = getDir("image");
		title = list[0];

		//Separate the image channels and duplicate the first for binary processing
		run("Split Channels");
		selectImage("C1-"+title);
		run("Duplicate...", " ");
		rename(bin);

		//Thresholding and binary operations to run analyze particles
		run("Median...", "radius=2");
		setAutoThreshold("Li dark");
		setOption("BlackBackground", true);
		run("Convert to Mask");
		//run("Close-");
		run("Fill Holes");
			
		run("Analyze Particles...", "size=1.50-Infinity circularity=0.25-1.00 clear add");
		close(bin);
	
		//Save ROIs
		roiManager("Save", save_dir + title + "_ROI.zip");

		//Creates Jpeg of red channel with the selections obtained from the analyze particles command
		selectImage("C1-"+title);
		run("Duplicate...", " ");
		run("Enhance Contrast", "saturated=0.35");
		roiManager("deselect");
		run("Labels...", "color=white font=18 show draw bold");
		roiManager("Set Color", "yellow");
		roiManager("Set Line Width", 2);		
		roiManager("Show All with labels");
		run("Flatten");		
		saveAs(".jpeg", save_dir + title + "_cell_Overlay.jpeg");
		close();
		roiManager("Show None");

		//Due to the nature of Airyscan images a duplicate green channel image is made 
		//and has the 10000 minimum intensity subtracted to help with calculations aka Normalized
		//Both are still analyzed
		selectImage("C2-"+title);
		run("Duplicate...", " ");
		rename(norm);
		
		selectImage(norm);
		run("Subtract...", "value=10000");

		//Get the whole green channel intensity values
		selectImage("C2-"+title);
		run("Measure");
		whole_rawintden = getResult("RawIntDen", 0);

		selectImage(norm);
		run("Measure");
		norm_rawintden = getResult("RawIntDen", 1);

		run("Clear Results");
		close("Results");

		roi_count =roiManager("count");

		//Loop over all the ROIs from analyze particles and measure area, 
		//band (capsule) intensity and cell+capsule intensity
		//Also saves each to a tsv table
		for (r = 0; r < roi_count; r++) {
			selectImage("C1-"+title);
			roiManager("select", r);
			run("Measure");
			cell_area = getResult("Area", 0);
			
			selectImage("C2-"+title);		
			roiManager("select", r);
			run("Make Band...", "band=1");
			roiManager("Update");
			run("Measure");
			whole_band_rawintden = getResult("RawIntDen", 1);

			selectImage(norm);		
			roiManager("select", r);
			run("Measure");
			norm_band_rawintden = getResult("RawIntDen", 2);

			selectImage("C2-"+title);		
			roiManager("select", r);
			roiManager("Split");
			run("Measure");
			whole_caps_rawintden = getResult("RawIntDen", 3);

			selectImage(norm);		
			roiManager("select", r);
			roiManager("Split");
			run("Measure");
			norm_caps_rawintden = getResult("RawIntDen", 4);
			
	
			run("Clear Results");
			close("Results");
	
			count = 0;
			//Re-open saved results if they exist for original image
			if (File.exists(save_dir + "All_Data_original.tsv")){
				open(save_dir + "All_Data_original.tsv");
				IJ.renameResults("All_Data_original.tsv", "Results");
				count = nResults;
			}
			
			//Fill in the results table, update, and save it
			setResult("ID - Image", count, title);
			setResult("ID - Cell", count, (r+1));			
			setResult("Cell Area", count, cell_area);
			setResult("Capsule Band - Raw Integrated Density", count, whole_band_rawintden);
			setResult("Capsule+Cell - Raw Integrated Density", count, whole_caps_rawintden);
			
			setResult("Whole Image - Raw Integrated Density", count, whole_rawintden);
			
			setResult("% band/whole - Raw Integrated Density", count, whole_band_rawintden/whole_rawintden);
			setResult("% capcell/whole - Raw Integrated Density", count, whole_caps_rawintden/whole_rawintden);
			
			updateResults();
			saveAs("Results", save_dir + "All_Data_original.tsv");
			run("Clear Results");
			close("Results");

			count = 0;
			//Re-open saved results if they exist for normalized image
			if (File.exists(save_dir + "All_Data_Norm.tsv")){
				open(save_dir + "All_Data_Norm.tsv");
				IJ.renameResults("All_Data_Norm.tsv", "Results");
				count = nResults;
			}
			
			//Fill in the results table, update, and save it
			setResult("ID - Image", count, title);
			setResult("ID - Cell", count, (r+1));			
			setResult("Cell Area", count, cell_area);
			setResult("Capsule Band - Raw Integrated Density", count, norm_band_rawintden);
			setResult("Capsule+Cell - Raw Integrated Density", count, norm_caps_rawintden);
			
			setResult("Whole Image - Raw Integrated Density", count, norm_rawintden);
			
			setResult("% band/whole - Raw Integrated Density", count, norm_band_rawintden/norm_rawintden);
			setResult("% capcell/whole - Raw Integrated Density", count, norm_caps_rawintden/norm_rawintden);
			
			updateResults();
			saveAs("Results", save_dir + "All_Data_Norm.tsv");
			run("Clear Results");
			close("Results");
		}

		//Save band selection ROI
		roiManager("Save", save_dir + title + "_band_ROI.zip");

		//Creates Jpeg of green channel with the band selections obtained from the analyze particles command
		selectImage("C2-"+title);
		run("Enhance Contrast", "saturated=0.35");
		roiManager("deselect");
		run("Labels...", "color=white font=18 show draw bold");
		roiManager("Set Color", "yellow");
		roiManager("Set Line Width", 2);		
		roiManager("Show All with labels");
		run("Flatten");		
		saveAs(".jpeg", save_dir + title + "_capsule_Overlay.jpeg");
		close();
	
		//Closes all images and resets workspace for next image 
		run("Close All");
		run("Clear Results");
		close("Results");
		roiManager("reset");

		//Check if while loop keeps running
		running = getBoolean("Do you wish to analyze another image?", "Yes", "No");
	}				
}