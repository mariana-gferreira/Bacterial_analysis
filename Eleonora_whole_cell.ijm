//For Eleonora CDiff Image Analysis
//Made with ImageJ 1.52i
//Made by Mariana Ferreira @ITQB NOVA

macro "Eleonora_CDiff_Analysis Action Tool - C000 T0b07C T6b07D Tcb07i Teb07f Thb07f" {
	//Prepares work environment to run the macro
	run("Close All");
	run("Clear Results");
	close("Results");
	roiManager("reset");
	selectWindow("ROI Manager"); 
	run("Close");
	run("Set Measurements...", "area mean redirect=None decimal=3");
	x=1000; y=250;
	call("ij.gui.WaitForUserDialog.setNextLocation",x,y);

	//Select directory and macro retrieves file list
	directory = getDirectory("Choose Directory with the Images");
	list = getFileList(directory);

	//creates base variables
	title = "1214_14h_#";
	first = "0";
	last = "210";
	skip = 0;
	increase = 0;
	total_cells = 0;
	current = 0;
	spore = newArray(0);
	mc = newArray(0);
	spore_area = newArray(0);
	mc_area = newArray(0);
	

	//Creates window where user can insert relevant information
	Dialog.create("Information - Images");
	Dialog.setInsets(5, 0, 5); 
	Dialog.addMessage("Example:\nFor Ptet-SNAP#_PHASE-1 insert Ptet-SNAP#.");
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
		image_phase = title +"_PHASE-"+ i + ".TIF";
		image_red = title +"_RED-"+ i + ".TIF";
		SN = title;

		//Checks for the existence of the selected file
		//Skips to next number if file does not exist
		if (File.exists(directory + image_phase) == 0) { 
			skip = skip+1;
    		continue;
		}

		setBatchMode(true);
		
		open(directory + image_phase);

		setAutoThreshold("Default");
		run("Convert to Mask");
		run("Create Selection");
		run("Convex Hull");
		roiManager("Add");
		run("Select None");
		floodFill(2, 2);
		run("Invert");
		run("Create Selection");
		run("Make Inverse");

		if (selectionType() == -1){
			skip = skip+1;
			close(image_phase);
			roiManager("reset");
    		continue;
		}
		//run("Enlarge...", "enlarge=-1");	
		run("Enlarge...", "enlarge=3");
		//run("Convex Hull");
		roiManager("Add");
		roiManager("Select", newArray(0,1));
		roiManager("XOR");
		roiManager("Add");
		close(image_phase);
		
		open(directory + image_phase);
		roiManager("Select", 2);
		run("From ROI Manager");
		//saveAs(".tif", directory + title+"_OverlayPHASE-" + i +".TIF");
		saveAs(".jpeg", directory + title+"_OverlayPHASE-" + i +".jpeg");		
		close(title+"_OverlayPHASE-" + i +".tif");
		

		open(directory + image_red);
		roiManager("Select", newArray(1,2));
		roiManager("Measure");

		spore = Array.concat(spore, getResult("Mean", 0));
		mc = Array.concat(mc, getResult("Mean", 1));
		spore_area = Array.concat(spore_area, getResult("Area", 0));
		mc_area = Array.concat(mc_area, getResult("Area", 1));
		run("Clear Results");
		close("Results");

		selectImage(image_red);
		roiManager("Select", 2);
		run("From ROI Manager");
		//saveAs(".tif", directory + title+"_Overlay-" + i +".TIF");
		saveAs(".jpeg", directory + title+"_Overlay-" + i +".jpeg");
		

		if ((i > 0)&&(File.exists(directory + "Spore_WholeMC_" + title + first + "_" + last + "_data.tsv"))){
			open(directory + "Spore_WholeMC_" + title + first + "_" + last + "_data.tsv");
			IJ.renameResults("Results");
		}

		
		setResult("ID", current, i);
		setResult("Spore MI", current, spore[current]);
		setResult("MC MI", current, mc[current]);	
		setResult("Spore Area", current, spore_area[current]);
		setResult("MC Area", current, mc_area[current]);		

		updateResults();
		saveAs("Results", directory + "Spore_WholeMC_" + title + first + "_" + last + "_data.tsv");
		
		run("Clear Results");
		roiManager("reset");
		close(image_red);
		close(title+"_Overlay-" + i + ".tif");
		current += 1;
		

	}
	run("Close All");
	run("Clear Results");
	close("Results");
	
}	
		
		
    	