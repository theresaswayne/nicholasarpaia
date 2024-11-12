
// paste the appropriate section of text into the process > batch > macro window 
// to process a whole folder


// BioVoxxel Pseudo Flat Field (will crash on large images)
title = getTitle();
run("Pseudo Flat Field Correction (2D/3D)", "flatfieldradius=50.0 force2dfilter=true activechannelonly=false showbackgroundimage=false stackslice=1");
selectImage(title);
close();
selectImage("PFFC_"+title);
rename(title);

// BaSiC correction calculated from all images in the stack
title = getTitle();
run("BaSiC ", "processing_stack=&title flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Automatic temporal_drift=Ignore correction_options=[Compute shading and correct images] lambda_flat=0.50 lambda_dark=0.50");
selectImage(title);
close();
selectImage("Corrected:"+title);
rename(title);
selectImage("Flat-field:"+title);
close();



