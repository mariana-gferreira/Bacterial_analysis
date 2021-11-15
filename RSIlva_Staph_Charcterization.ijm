//For Rodrigo Silva @RSL@ITQB
//Made with ImageJ 1.53c
//Made by Mariana Ferreira @ITQB NOVA

macro "Staph Characterization Action Tool - C000 T0b07S T5b07t T9b07a Tdb07p Tgb07h" {
	//Prepares work environment to run the macro
	requires("1.53c");
	run("Close All");
	run("Clear Results");
	close("Results");
	roiManager("reset");
	selectWindow("ROI Manager"); 
	run("Close");
	run("Set Measurements...", "area mean min perimeter fit redirect=None decimal=3");
	x=1000; y=250;
	call("ij.gui.WaitForUserDialog.setNextLocation",x,y);

	//Check if required Plugins are installed
	List.setCommands;
    if (List.get("Mexican Hat Filter")=="") {
    	waitForUser("The Mexican Hat Filter Plugin is required to run this macro.\nPlease install it and try again.");
    	exec("open", "https://imagej.nih.gov/ij/plugins/mexican-hat/index.html");
    	exit();
    }
    List.clear();
    running = true;

	while (running == true) {

	//Resetable Variables
	count = 0;
	data_table = "All_Data";
	num_table = 1;

    //Select directory and macro retrieves file list
	directory = getDirectory("Choose Directory with the Images");
	list = getFileList(directory);

	//Create sub-folder for results
	save_dir = directory + "/Results/";
	File.makeDirectory(save_dir);
	
	//When the script is first run checks for previous data tables in the folder to prevent overwriting
	if(count == 0){
		while ((File.exists(save_dir + data_table + ".tsv")) == 1) {
			data_table = "All_Data_"+ IJ.pad(num_table, 3);
			num_table++;
		}
	}

	

	//begins loop through folder file list
	for(l = 0; l < lengthOf(list); l++){
		//Enables batch mode to speed up analysis
		setBatchMode(true);
		
		//Check to open only .nd files in the folder so images are calibrated
		if(endsWith(list[l], ".nd")==false){
			continue;		
		}

		//Opens file and gets file name for saving purposes
		run("Bio-Formats Windowless Importer", "open=["+ directory + list[l] +"]");
		work_img = getTitle();
		save_name = split(list[l], ".");
		save_name = save_name[0];

		//Checks if images have all the channels to prevent crashing
		getDimensions(width, height, channels, slices, frames);
		if ( channels != 4){
			waitForUser("This image does not have enough channels.");
			close();
			continue;
		}

		//Forces scale to 100x 1.6 optovar
		run("Set Scale...", "distance=1 known=0.05 unit=micron");

		//Extracts Channel names and order for color and analysis assigments
		split_image_info = split(getInfo(),"\n\n");
		series_0_name = split(split_image_info[6],"=");
		series_channels = split(series_0_name[1],"/");

		for (s = 0; s < lengthOf(series_channels); s++) {
			if (series_channels[s] == "TX2") { red = s+1;}
			if (series_channels[s] == "FITC") { green = s+1;}
			if (series_channels[s] == "DAPI") { blue = s+1;}
		}
		
		//Create cell mask from phase image and create cell ROIs
		run("Duplicate...", "title=Binary duplicate channels=1");
		run("Mexican Hat Filter", "radius=4");
		setThreshold(0, 500);
		run("Convert to Mask");
		run("Fill Holes");
		run("Watershed");
		
		run("Analyze Particles...", "size=150-Infinity pixel circularity=0.60-1.00 exclude clear add");
		roiManager("Save", save_dir + save_name + "_cell_ROIs.zip");
		close("Binary");
		if(roiManager("count") == 0){
			close(work_img);
			continue;
		}
		roi_count = roiManager("count");

		//Create iolated channel images with color
		selectImage(work_img);
		run("Duplicate...", "title=TL duplicate channels=1");
		
		selectImage(work_img);
		run("Duplicate...", "title=Red duplicate channels=" + red);
		run("Red");
		
		selectImage(work_img);
		run("Duplicate...", "title=Green duplicate channels=" + green);
		run("Green");
		run("Duplicate...", "title=Blur duplicate");
		run("Gaussian Blur...", "sigma=100");
		imageCalculator("Subtract", "Green","Blur");
		close("Blur");
		
		selectImage(work_img);
		run("Duplicate...", "title=Blue duplicate channels=" + blue);
		run("Blue");
		
		//Create nuclei selection mask ROI and save it
		run("Duplicate...", "title=Blur duplicate");
		run("Gaussian Blur...", "sigma=100");
		imageCalculator("Subtract", "Blue","Blur");
		close("Blur");
		setAutoThreshold("Default dark");
		run("Create Selection");
		roiManager("Add");

		roiManager("select", roi_count);
		roiManager("Save", save_dir + save_name + "_Nuclei_ROI.roi");

		run("Clear Results");
		//Re-open saved results if they exist for original image
		if (File.exists(save_dir + data_table +".tsv")){
			open(save_dir + data_table + ".tsv");
			IJ.renameResults(data_table + ".tsv", "Results");
			count = nResults;
		}

		//Loop cel ROIs
		for(r = 0; r < roi_count; r++){	
			//Live-Dead assay check
			selectImage("Green");
			roiManager("Deselect");
			roiManager("Show None");
			roiManager("select", r);
			setResult("ID-Image", count, save_name);	
			setResult("Cell Count", count, r+1);
			setResult("Mean Green Intensity", count, getValue("Mean"));
			if (getValue("Mean") > 1000) {
				roiManager("select", r);
				run("Add Selection...");
			}
			
			//Phase cell ROI measurements	
			selectImage("TL");
			roiManager("select", r);			
			setResult("Cell Area um2", count, getValue("Area"));
			setResult("Cell Perimeter um", count, getValue("Perim."));
			setResult("Cell Major Diameter um", count, getValue("Major"));
			setResult("Cell Minor Diameter um", count, getValue("Minor"));

			//Nucleus ROI Measurements for the current cell
			roiManager("Select", newArray(r, roi_count));
			roiManager("AND");
			if ( selectionType() != -1){
				setResult("Nucleus Area um2", count, getValue("Area"));
				setResult("Nucleus Perimeter um", count, getValue("Perim."));
				setResult("Nucleus Major Diameter um", count, getValue("Major"));
				setResult("Nucleus Minor Diameter um", count, getValue("Minor"));
			}

			count++;
			updateResults();
		}

		updateResults();
		saveAs("Results", save_dir + data_table + ".tsv");
		run("Clear Results");
		close("Results");
		
		//Save jpegs with multiple overlays of the ROIs
		selectImage("Green");
		run("Overlay Options...", "stroke=red width=2 fill=none apply");
		run("Flatten");
		saveAs(".jpeg", save_dir + save_name + "_Green_Dead.jpeg");

		selectImage("Blue");
		run("Remove Overlay");
		roiManager("Show None");
		resetThreshold();
		roiManager("select", roi_count);
		run("Add Selection...");
		run("Overlay Options...", "stroke=yellow width=2 fill=none apply");
		run("Flatten");
		saveAs(".jpeg", save_dir + save_name + "_DAPI_Nuclei.jpeg");

		roiManager("select", roi_count);
		roiManager("delete");
		
		selectImage("TL");
		run("Remove Overlay");
		run("Select None");
		run("Duplicate...", "duplicate");
		roiManager("deselect");
		run("Labels...", "color=white font=18 show draw bold");
		roiManager("Set Color", "yellow");
		roiManager("Set Line Width", 2);		
		roiManager("Show All with labels");
		run("Flatten");		
		saveAs(".jpeg", save_dir + save_name + "_cell_label_Overlay.jpeg");

		selectImage("TL");
		run("Remove Overlay");
		run("Select None");
		run("Duplicate...", "duplicate");
		roiManager("deselect");
		run("Labels...", "color=white font=18 show draw bold");
		roiManager("Set Color", "yellow");
		roiManager("Set Line Width", 2);		
		roiManager("Show All without labels");
		run("Flatten");		
		saveAs(".jpeg", save_dir + save_name + "_cell_Overlay.jpeg");

		//Closes all images and resets workspace for next image 
		run("Close All");
		run("Clear Results");
		close("Results");
		roiManager("reset");
	}
	//Check if while loop keeps running
	running = getBoolean("Do you wish to analyze another Folder?", "Yes", "No");
}
exit("Macro is finished!");
}

	
