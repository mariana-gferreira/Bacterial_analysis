//For Leonor Duarte @MDL@ITQB
//Made with ImageJ 1.53c
//Made by Mariana Ferreira @ITQB NOVA

macro "CDiff_SNAP_Quant Action Tool - C000 T0b07C T6b07D Tcb07i Teb07f Thb07f" {
	//Prepares work environment to run the macro
	run("Close All");
	run("Clear Results");
	close("Results");
	roiManager("reset");
	selectWindow("ROI Manager"); 
	run("Close");
	run("Set Measurements...", "area mean min redirect=None decimal=3");
	x=1000; y=250;
	call("ij.gui.WaitForUserDialog.setNextLocation",x,y);

	//Check if required Plugins are installed
	List.setCommands;
    if (List.get("Mexican Hat Filter")=="") {
    	waitForUser("The Mexican Hat Filter Plugin is required to run this macro.\nPlease install it and try again.");
    	exec("open", "https://imagej.nih.gov/ij/plugins/mexican-hat/index.html");
    	exit();
    }

	//Select directory and macro retrieves file list
	directory = getDirectory("Choose Directory with the Images");
	list = getFileList(directory);

	//creates variables and arrays
	title = "controlo 2 horas #";
	first = "1";
	last = "15";
	count = 0;
	count_bg = 0;
	
	snap_mean = newArray(0);
	snap_min = newArray(0);
	snap_max = newArray(0);
	snap_area = newArray(0);

	//Creates window where user can insert relevant information
	Dialog.create("Information - Images");
	Dialog.setInsets(5, 0, 5); 
	Dialog.addMessage("Example:\nFor Ptet-SNAP#1_w2TX2 insert Ptet-SNAP#.");
	Dialog.addString("Common Image Name:", title);
	Dialog.setInsets(5, 0, 5);
	Dialog.addMessage("Insert Number Range");
	Dialog.addString("From:", first);
	Dialog.addString("To:", last);
	Dialog.show();

	//Creates variables from user input
	title = Dialog.getString();
	first = Dialog.getString();
	last = Dialog.getString();

	//Prevents macro from proceding if the numbers where entered incorrectly
	if (parseInt(first) > parseInt(last)) {
		exit ("First number is bigger than the Last!");
	}

	//Begins loop that will go through all the images in the specified range
	for (i=first; i<=last; i++) {
		image_phase = title + i + "_w1Bright Field Phase .TIF";
		image_red = title + i + "_w3CY3-new-configuration.TIF";
		SN = title + i;

		//Checks for the existence of the selected file
		//Skips to next number if file does not exist
		if (File.exists(directory + image_phase) == 0) { 
    		continue;
		}

		//Opens phase image
		open(directory + image_phase);

		//Runs Filter, makes threshold, finds particles
		run("Mexican Hat Filter", "radius=5");
		setThreshold(0, 8500);
		run("Analyze Particles...", "size=350-2000 exclude clear add");

		close(image_phase);

		//Checks if any particles were found, skips to next image if not.
		if (roiManager("count")==0){			
			continue;
		}

		//open red channel,check image and get background value
		open(directory + image_red);
		state = getBoolean("Is this image good for analysis?", "Yes", "No");
		if (state == false){
			run("Close All");
			continue;
		}
		roiManager("Show All without labels");
		makeRectangle(20, 20, 100, 100);
		waitForUser("Move the square to a free background area.\nThen click OK");
		roiManager("Show None");
		roiManager("add");
		
		//Save ROIs
		roiManager("Save", directory + SN + "_ROI.zip");

		//Measure background intensity
		roiManager("select", roiManager("count")-1);
		run("Measure");
		bg_mean = getResult("Mean", 0);
		roiManager("select", roiManager("count")-1)
		roiManager("delete");
		run("Clear Results");

		//Measure the intensity in each of the cells and stores the values in an array
		for(r = 0; r < roiManager("count"); r++){
			roiManager("select", r);
			run("Measure");
			snap_mean = Array.concat(snap_mean,getResult("Mean", 0));
			snap_min = Array.concat(snap_min,getResult("Min", 0));
			snap_max = Array.concat(snap_max,getResult("Max", 0));
			snap_area = Array.concat(snap_area,getResult("Area", 0));

			run("Clear Results");
			close("Results");

			//Re-open saved results if they exist
			if (count > 0){
				open(directory + title + "_Data.tsv");
				IJ.renameResults(title + "_Data.tsv", "Results");
			}

			//Fill in the results table, update, and save it
			setResult("ID-Image", count, SN);
			setResult("ID - Cell", count, (count));			
			setResult("Cell Area Pixel", count, snap_area[count]);
			setResult("Cell Area µm2", count, (snap_area[count]*0.05*0.05));
			setResult("Minimum Cell Intensity", count, snap_min[count]);
			setResult("Maximum Cell Intensity", count, snap_max[count]);
			setResult("Mean Cell Intensity", count, snap_mean[count]);
			setResult("Mean Background Intensity", count, bg_mean);
			setResult("Mean ADJUSTED Intensity", count, (snap_mean[count]-bg_mean));

			updateResults();
			saveAs("Results", directory + title + "_Data.tsv");
			run("Clear Results");
			close("Results");

			count +=1;
		}

		//Makes the image Red
		//Adjusts Histogram with bg mean as min value
		selectImage(image_red);
		run("Red");
		getMinAndMax(min, max);
		setMinAndMax(bg_mean, max);

		//Saves visual representation of the cells
		roiManager("deselect");
		run("Labels...", "color=white font=18 show draw bold");
		roiManager("Set Color", "yellow");
		roiManager("Set Line Width", 2);		
		roiManager("Show All with labels");
		run("Flatten");		
		saveAs(".jpeg", directory + SN + "_red_Overlay.jpeg");

		//Closes all images and resets workspace for next image 
		run("Close All");
		run("Clear Results");
		close("Results");
		roiManager("reset");
		selectWindow("ROI Manager"); 
		run("Close");
				

	}
}