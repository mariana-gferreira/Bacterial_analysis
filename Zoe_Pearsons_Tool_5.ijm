//Made with ImageJ 1.52p
//Made by Mariana Ferreira @ITQB NOVA

macro "Zoe_CDiff Action Tool - C000 T0b07C T6b07D Tcb07i Teb07f Thb07f" {
	//Prepares work environment to run the macro
	run("Close All");
	run("Clear Results");
	close("Results");
	roiManager("reset");
	selectWindow("ROI Manager"); 
	run("Close");
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

			if(getValue("Mean" == 0){
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

			if(getValue("Mean" == 0){
				close();
				continue;
			}
			
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

//-------------------------- Begining of folder Loop Macro --------------------------------------

macro "Zoe_CDiff_LOOP_Analysis Action Tool - C000 T0b09L T5b09o Tab09o Tfb09p" {
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

//Make new folders for seen images
	title = File.getName(directory);
	reject = directory + "/Rejected_" + title + "/";
	File.makeDirectory(reject);
	accept = directory + "/Accepted_" + title + "/";
	File.makeDirectory(accept);

//Loop through files in directory, show a dialog to keep or reject the image and move it to another folder
	for(i = 0; i < lengthOf(list); i++){
		if(endsWith(list[i], ".tif")==false){
			continue;		
		}
		open(directory + list[i]);

		resetMinAndMax();
		run("Make Composite");
		
		state = getBoolean("Is this image good for analysis?", "Yes", "No");
		
		if(state == true){
			saveAs(".tif", accept + list[i]);
			ok = File.delete(directory + list[i]);
			close();
		}
		if (state == false){
			saveAs(".tif", reject + list[i]);
			ok = File.delete(directory + list[i]);
			close();
		}
	}
	
	exit("Macro is finished!");
}

//-------------------------- Begining of Analysis Macro --------------------------------------

macro "Zoe_CDiff_Analysis Action Tool - C000 T0b09C T6b09o Tbb09r Teb09r" {
//Prepares work environment to run the macro
	run("Close All");
	run("Clear Results");
	close("Results");
	roiManager("reset");
	selectWindow("ROI Manager"); 
	run("Close");
	run("Set Measurements...", "mean redirect=None decimal=3");
	x = 1000; y = 250;
	call("ij.gui.WaitForUserDialog.setNextLocation",x,y);

//Select directory and macro retrieves file list
	directory = getDirectory("Choose Directory with the Images");
	list = getFileList(directory);

//Misc Variables
	title = File.getName(directory);
	title_2 = File.getName(File.getParent(directory));
	save_dir = File.getParent(directory);
	pearson = newArray(0);
	M1 = newArray(0);
	M2 = newArray(0);
	tM1 = newArray(0);
	tM2 = newArray(0);
	ori_image = newArray(0);
	ori_crop = newArray(0);
	area_red = newArray(0);
	area_green = newArray(0);

//Starts Loop through images in the directory and analyzes them
	setBatchMode(true);
	for(i = 0; i < lengthOf(list); i++){	
		if(endsWith(list[i], ".tif")==false){
			continue;		
		}	
		open(directory + list[i]);
		tifless = split(list[i], ".");
		id_comp = split(tifless[0], "_");

	//Image processing for analysis
		Stack.setChannel(1);
		run("Subtract Background...", "rolling=5 slice");

		run("BIOP JACoP", "channel_a=1 channel_b=2 threshold_for_channel_a=Otsu threshold_for_channel_b=Otsu manual_threshold_a=0 manual_threshold_b=0 get_pearsons get_manders costes_block_size=5 costes_number_of_shuffling=100");
	
	//Stores analysis results in multiple arrays
		pearson = Array.concat(pearson, getResult("Pearson's Coefficient", i));	
		M1 = Array.concat(M1, getResult("M1", i));
		M2 = Array.concat(M2, getResult("M2", i));
		tM1 = Array.concat(tM1, getResult("Thresholded M1", i));
		tM2 = Array.concat(tM2, getResult("Thresholded M2", i));
		area_red = Array.concat(area_red, getResult("Area A", i));
		area_green = Array.concat(area_green, getResult("Area B", i));
		ori_image = Array.concat(ori_image, tifless[0]);
		if(lengthOf(id_comp)==6){
			ori_crop = Array.concat(ori_crop, id_comp[5]);
		}
		if(lengthOf(id_comp)==7){
			ori_crop = Array.concat(ori_crop, id_comp[6]);
		}
		

		close(list[i]);
		close(list[i]+ " Report");
	}
	
	run("Clear Results");
	close("Results");

//Assembles array data results in a table
	for (l = 0; l < lengthOf(pearson); l++){		
		setResult("Image" ,l ,ori_image[l]);
		setResult("Count" ,l , IJ.pad(ori_crop[l], 3));
		setResult("Pearson's Corr" ,l ,pearson[l]);
		setResult("M1" ,l ,M1[l]);
		setResult("M2" ,l ,M2[l]);
		setResult("tM1" ,l ,tM1[l]);
		setResult("tM2" ,l ,tM2[l]);
		setResult("Area Red um^2" ,l ,area_red[l]);
		setResult("Area Green um^2" ,l ,area_green[l]);
		updateResults();		
	}

	saveAs("Results", save_dir + "/" + title_2 +"_Data.tsv");
	run("Clear Results");
	close("Results");
	close("Log");

	exit("Macro is finished!");
}