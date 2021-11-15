//For Clostridium difficile analysis red stain quantification
//Made with ImageJ 1.53c
//Made by Mariana Ferreira @ITQB NOVA

macro "CDiff_SPORES Action Tool - C000 T0b07C T6b07D Tcb07i Teb07f Thb07f" {

	//Prepares work environment to run the macro
	run("Close All");
	run("Clear Results");
	close("Results");
	roiManager("reset");
	selectWindow("ROI Manager"); 
	run("Close");
	run("Set Measurements...", "mean min redirect=None decimal=3");
	run("Point Tool...", "type=Circle color=Yellow size=Medium label counter=0");
	x=1000; y=250;
	call("ij.gui.WaitForUserDialog.setNextLocation",x,y);

	//Select directory and macro retrieves file list
	directory = getDirectory("Choose Directory with the Images");
	list = getFileList(directory);

	//creates variables and arrays
	title = "PsdaB empty 8h #";
	first = "1";
	last = "15";
	count = 0;
	stop = 0;
	
	red_int = newArray(0);

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

	//Prevents macro from proceding if the numbers were entered incorrectly
	if (parseInt(first) > parseInt(last)) {
		exit ("First number is bigger than the Last!");
	}

	save_dir = directory + "/" + title + "_JPEG/";
	File.makeDirectory(save_dir);

	//Begins loop that will go through all the images in the specified range
	for (i=first; i<=last; i++) {
		image_phase = title + i + "_w1Bright Field Phase .TIF";
		image_phase_2 = title + i + "_w1Bright Field Phase.TIF";
		image_red = title + i + "_w2CY3-new-configuration.TIF";
		SN = title + i;

		//Checks for the existence of the selected file
		//Skips to next number if file does not exist
		if ((File.exists(directory + image_phase) == 0) && (File.exists(directory + image_phase_2) == 0)) { 
    		continue;
		}

		//Forces the screen location of the new image
		//Opens the phase image even if it lost the space at the end of the file name
		call("ij.gui.ImageWindow.setNextLocation", 100, 100);
		if (File.exists(directory + image_phase) == 0) {
			open(directory + image_phase_2);
		}else{
			open(directory + image_phase);
		}
		rename(image_phase);
		saveAs(".jpeg", save_dir + image_phase);

		//Forces location of the second image so it is side by side with the first
		//Might not work on all screen resolutions
		//Opens red channel image and gives fake colour
		call("ij.gui.ImageWindow.setNextLocation", 750, 100);
		open(directory + image_red); 
		run("Red");

		//Does contrast adjustment
		makeRectangle(100, 100, 100, 100);
		waitForUser("Move selection to background area.");
		run("Measure");
		run("Select None");
		bg_1 = getResult("Mean", 0);
		close("Results");
		getMinAndMax(min, max);
		setMinAndMax(bg_1, max);
		saveAs(".jpeg", save_dir + image_red);
		
		if (max > 1500) {
			max=1500;			
		}
		setMinAndMax(bg_1, max);

		//Set multipoint tool and open Sync windows to see mouse location on both
		setTool("multipoint");
		run("Synchronize Windows");

		waitForUser("Select sync all and\nuse the multipoint tool\nto select the areas of interest\nthen click OK");

		//Fail safe in case no points are selected
		if (selectionType() == -1){
			continue;
		}

		//Add to ROI manager and save ROIs as zip
		selectImage(image_red);
		roiManager("Add");
		roiManager("Save", directory + SN + "_ROI.zip");

		close(image_phase);

		//Extract point coordinates from ROI
		roiManager("select", 0);
		Roi.getCoordinates(xpoints, ypoints);

		//Makes an image of red channel with the ROi points for reference
		selectImage(image_red);			
		roiManager("select", 0);
		roiManager("Show All without labels");		
		run("Flatten");
		saveAs(".jpeg", save_dir + SN + "_Point_Overlay");
		close();		
		
		roiManager("reset");

		//Loop through point coordinates and makes circular regions and measures intensity
		for(r = 0; r < lengthOf(xpoints); r++){
			selectImage(image_red);
			makeOval(xpoints[r]-3, ypoints[r]-3, 6, 6);
			run("Measure");
			red_int = Array.concat(red_int,getResult("Mean", 0));

			run("Clear Results");
			close("Results");

			//In case a tsv already exists opens it and updates with new data
			if (count > 0){
				open(directory + title + "_Data.tsv");
				IJ.renameResults(title + "_Data.tsv", "Results");
			}

			//Adds results to table
			setResult("ID-Image", count, SN);
			setResult("ID", count, r+1);
			setResult("Background intensity", count, bg_1);
			setResult("Mean intensity", count, red_int[count]);
			setResult("Mean-BG intensity", count, red_int[count]-bg_1);
			updateResults();

			//Save table
			saveAs("Results", directory + title + "_Data.tsv");
			run("Clear Results");
			close("Results");

			//Count increases and checks for number of cells counted
			count += 1;
			if(count > 100){
				stop=getBoolean("You have 100 cells analyzed.\nDo you want to stop?");
			}
		}

		run("Close All");

		//If enough cells were counted ends the for loop
		if(stop == 1){
			break;
		}

	}
	//Final clean up of workspace
	run("Close All");
	run("Clear Results");
	close("Results");
	roiManager("reset");
	selectWindow("ROI Manager"); 
	run("Close");
	close("Synchronize Windows");
}

		

		