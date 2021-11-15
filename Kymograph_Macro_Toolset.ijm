//Made with ImageJ 1.53k
//Made by Mariana Ferreira @ITQB NOVA
//July 2021

//---------------Crop Macro--------------

macro "CDiff_Crop Action Tool - C000 T0b08C T8b08r Tbb08o Tgb08p" {
	//Prepares work environment to run the macro
	run("Close All");
	run("Clear Results");
	close("Results");
	roiManager("reset");
	run("Set Measurements...", "area mean shape redirect=None decimal=3");
	x = 1000; y = 250;
	call("ij.gui.WaitForUserDialog.setNextLocation",x,y);
	run("Bio-Formats Macro Extensions");

	repeat = true;

	while (repeat == true) {	
	//Select directory and macro retrieves file list
		file_directory = File.openDialog("Choose Image");
		directory = File.getDirectory(file_directory);
		list = getFileList(directory); 
	
		Ext.setId(file_directory);
		Ext.getSeriesCount(seriesCount);
	
	//Variables and arrays for the dialog and loops
		trans_x = 0;
		trans_y = 0;
	
	//Makes a new folder inside the selected directory
		img_id = File.getNameWithoutExtension(file_directory);
		
		save_dir = directory + "/" + img_id + "/";
		File.makeDirectory(save_dir);

		save_dir_2 = directory + "/Overlays/";
		File.makeDirectory(save_dir_2);
	
	//Start image opening loop
		work_img = File.getName(file_directory);
		
	//Checks for the existence of the selected file
	//Skips to next number if file does not exist
		if (File.exists(directory + work_img) == 0) { 
	   		continue;
		}
	
		for(s = 1; s<= seriesCount; s++){
		//Open czi file
			run("Bio-Formats Importer", "open=[" + file_directory + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + s);
			work_img = getTitle();
			c1_img = "C1-" + work_img; 
			c2_img = "C2-" + work_img; 

			if(getValue("Mean" == 0)){
				close();
				continue;
			}
	
			Stack.setDisplayMode("composite");
			Stack.setChannel(1);
			getMinAndMax(min_1, max_1);
			run("Enhance Contrast", "saturated=0.35");
			Stack.setChannel(2);
			getMinAndMax(min_2, max_2);
			run("Enhance Contrast", "saturated=0.35");
			run("Maximize");
			run("Set... ", "zoom=50 x=1578 y=1578");
			Stack.setChannel(1);
			
			
			translation = getBoolean("Do the fluorescence channels need translating to align?", "No", "Yes");
			while (translation == false){
				Dialog.create("Green Channel Translation");
				Dialog.setInsets(5, 0, 5);
				Dialog.addString("Translate X (px):", trans_x);
				Dialog.addString("Translate Y (px):", trans_y);
				Dialog.show();
				trans_x= Dialog.getString();
				trans_y= Dialog.getString();
	
				Stack.setChannel(2);
				run("Translate...", "x="+trans_x+" y="+trans_y+" interpolation=None slice");
				translation = getBoolean("Do the fluorescence channels need translating to align?", "It's Good", "More Adjustments");
			}
			
			Stack.setChannel(1);		
			setMinAndMax(min_1, max_1);
			Stack.setChannel(2);		
			setMinAndMax(min_2, max_2);
			run("Original Scale");
			
			setBatchMode(true);

			selectImage(work_img);
			run("Split Channels");

			selectImage(c1_img);
			run("Duplicate...", "duplicate");			
			rename("Blur");
			run("Gaussian Blur...", "sigma=200");
			imageCalculator("Subtract", c1_img,"Blur");
			close("Blur");
			resetMinAndMax();

			selectImage(c2_img);
			run("Duplicate...", "duplicate");
			rename("Blur");
			run("Gaussian Blur...", "sigma=100");
			imageCalculator("Subtract", c2_img,"Blur");
			close("Blur");
			resetMinAndMax();

			run("Merge Channels...", "c1=[" + c1_img + "] c2=[" + c2_img + "] create");


			selectImage(work_img);
			run("Duplicate...", "duplicate channels=1");
			rename("Overlay");
			selectImage(work_img);
			run("Duplicate...", "duplicate channels=1");
			rename("Binary");
						
		//Makes threshold using image stack, Analyze Particles used to select individual cells
		//Saves ROIs of selected cells
			selectImage("Binary");
			setAutoThreshold("Li dark");
			run("Convert to Mask");
			run("Close-");
			run("Fill Holes");
			run("Median...", "radius=8");
	
			run("Analyze Particles...", "size=3-25 exclude clear add");
			roiManager("Save", save_dir + img_id + "_"+ s + "_ROIs.zip");
			close("Binary");
				if(roiManager("count") == 0){
				continue;
			}
						
		//Loops through all ROIs, duplicates selections and saves images in TIFF		
			for(r = 0; r < roiManager("count"); r++){
				selectImage(work_img);
				roiManager("select", r);

				roundness = getValue("Round");
				if (roundness > 0.4) {
					continue;
				}

				run("To Bounding Box");
				run("Enlarge...", "enlarge=10 pixel");
				run("Duplicate...", "duplicate");
				resetMinAndMax();
				Stack.setChannel(2);
				resetMinAndMax();
							
				saveAs(".tif", save_dir + img_id + "_" + IJ.pad(s, 2) + "_" + IJ.pad(r+1, 3) +".TIF");		
				close();

				selectImage("Overlay");
				roiManager("select", r);
				run("Add Selection...");
							
			}
			close(work_img);

			selectImage("Overlay");
			roiManager("Deselect");
			roiManager("Show None");
			run("Overlay Options...", "stroke=yellow width=5 fill=none set");			
			resetMinAndMax();
			run("Enhance Contrast...", "saturated=0.35");
			run("Flatten");
			saveAs(".jpeg", save_dir_2 + img_id + "_" + s + "_Overlay.jpeg");	
			run("Close All");

			setBatchMode(false);
		}
		
		setBatchMode(false);
		repeat = getBoolean("Do you wish to process another image?", "Yes", "No");
	}
	
	exit("Macro is finished!");
}	

//--------------Straighten Loop Macro-------

macro "Straighten_LOOP_Analysis Action Tool - C000 T0b09L T6b09i T9b09n Tfb09e" {
//Prepares work environment to run the macro
	run("Close All");
	run("Clear Results");
	close("Results");
	roiManager("reset");
	selectWindow("ROI Manager"); 
	run("Close");
	x = 1000; y = 250;
	call("ij.gui.WaitForUserDialog.setNextLocation",x,y);

//Select directory and macro retrieves file list
	directory = getDirectory("Choose Directory with the Images");
	list = getFileList(directory);

//Make new folders for straightned cells and done images
	title = File.getName(directory);
	straight = directory + "/Straightned_" + title + "/";
	File.makeDirectory(straight);
	done = directory + "/Done_" + title + "/";
	File.makeDirectory(done);

//Loop through files in directory, show a dialog to keep or reject the image and move it to another folder
	for(i = 0; i < lengthOf(list); i++){
		if(endsWith(list[i], ".tif")==false){
			continue;		
		}
		open(directory + list[i]);
		run("In [+]");
		getDimensions(width, height, channels, slices, frames);
		setLocation(screenWidth/2 - width, screenHeight/2 - height);		
		tifless = split(list[i], ".");

		resetMinAndMax();
		run("Make Composite");
		
		setTool("polyline");
		waitForUser("Draw a segmented line over your cell then click OK.\nRight click on the last position to end selection.\nIf no selection is made the image will be skipped.");

		if (selectionType()==-1){
			close();
			continue;
		}

		//setBatchMode(true);
		
		roiManager("Add");
		Stack.setDisplayMode("color");
		
		Stack.setChannel(1);
		run("Straighten...", "title=[" + tifless[0] + "_red] line=40");
		saveAs(".tif", straight + tifless[0] + "_red.tif");
		close();

		Stack.setChannel(2);
		run("Straighten...", "title=[" + tifless[0] + "_green] line=40");
		saveAs(".tif", straight + tifless[0] + "_green.tif");
		getDimensions(width, height, channels, slices, frames);
		close();
		
		count = 0;
	//Re-open saved results if they exist for normalized image
		if (File.exists(straight + "x_size_list.tsv")){
			open(straight + "x_size_list.tsv");
			IJ.renameResults("x_size_list.tsv", "Results");
			count = nResults;
		}
		
	//Fill in the results table, update, and save it
		setResult("ID - Image", count, tifless[0]);
		setResult("Width", count, width);		
			
		updateResults();
		saveAs("Results", straight + "x_size_list.tsv");
		run("Clear Results");
		close("Results");

	//Moves original image into another folder
		selectImage(list[i]);
		saveAs(".tif", done + list[i]);
		ok = File.delete(directory + list[i]);
		close();

	//Save ROI
		roiManager("Save", straight + "ROIs.zip");
	}

}


//-------------Kymograph Macro------------


macro "Kymograph_Analysis Action Tool - C000 T0b07K T5b07y Tab07m Thb07o" {
//Prepares work environment to run the macro
	run("Close All");
	run("Clear Results");
	close("Results");
	roiManager("reset");
	selectWindow("ROI Manager"); 
	run("Close");
	x = 1000; y = 250;
	call("ij.gui.WaitForUserDialog.setNextLocation",x,y);

//Select directory and macro retrieves file list
	directory = getDirectory("Choose Directory with the Images");
	list = getFileList(directory);
	title = File.getName(directory);

	if (File.exists(directory + "x_size_list.tsv")){
		open(directory + "x_size_list.tsv");
		IJ.renameResults("x_size_list.tsv", "Results");
		count = nResults;
	}else{
		exit("x_size_list file is missing from folder.");
	}

	Table.sort("Width");

	setBatchMode(true);

	for(c = 0; c < count; c++){
		open(directory + getResultString("ID - Image", c)+"_red.tif");		
		open(directory + getResultString("ID - Image", c)+"_green.tif");		
	}

	
	run("Images to Stack", "method=[Copy (center)] name=RED title=_red use");
	run("Images to Stack", "method=[Copy (center)] name=GREEN title=_green use");

	//setBatchMode("exit and display");

	selectImage("RED");
	getDimensions(width, height, channels, slices, frames);
	makeLine(0, height/2, width, height/2, height);
	run("Multi Kymograph", "linewidth=1");
	run("Rainbow RGB");
	saveAs(".tif", directory + title + "_Kymograph_Red");

	selectImage("GREEN");
	getDimensions(width, height, channels, slices, frames);
	makeLine(0, height/2, width, height/2, height);
	run("Multi Kymograph", "linewidth=1");
	run("Rainbow RGB");
	saveAs(".tif", directory + title + "_Kymograph_Green");

	close("*");
	close("Results");
	
	exit("Macro is finished!");

}
