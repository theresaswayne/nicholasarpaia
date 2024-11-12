#@ File(label = "Treg label image:") TregFile
#@ File(label = "Fibroblast label image:") FbFile
#@ File(label = "Output folder:", style = "directory") outDir

# take 2 label image stacks representing 2D tracked cells over time
# use DiAnA to determine which cells in the first image overlap cells in the 2nd

# ---- Setup ----
import os
import math
import io
from net.imglib2.view import Views
from ij import IJ, ImagePlus, ImageStack
from ij.process import ImageProcessor, FloatProcessor, StackProcessor
import string
from ij.measure import ResultsTable
from ij import WindowManager



# ---- Load files ----

TregImp = IJ.openImage(str(TregFile))
FbImp = IJ.openImage(str(FbFile))

TregStack = TregImp.getStack() # get the stack within the ImagePlus
FbStack = FbImp.getStack() # get the stack within the ImagePlus

n_slices = TregStack.getSize() # get the number of slices

wm = WindowManager
outputdir = str(outDir)

# ---- Loop over slices ---- 

for index in range(1, n_slices+1):
	TregIp = TregStack.getProcessor(index) 
	FbIp = FbStack.getProcessor(index)
	IJ.log("Processing slice " + str(index)) # output info on current slice
	TsliceName = "Treg_" + str(index)
	TsliceImp = ImagePlus(TsliceName, TregIp) # give the imp a name to use with DiAnA
	TsliceImp.show()
	FsliceName = "Fb_" + str(index)
	FsliceImp = ImagePlus(FsliceName, FbIp)
	FsliceImp.show()
	
	# find overlaps
	IJ.run("DiAna_Analyse", "img1="+TsliceName+" img2="+FsliceName+" lab1="+TsliceName+" lab2="+FsliceName+" coloc")
	
	# save results
	outputName = string.join((str(index), "_ColocResults.csv"), "")
	print("Saving as", outputName)
	rt_Window= WindowManager.getWindow("ColocResults")
	rt = rt_Window.getResultsTable()
	rt.save(os.path.join(outputdir, outputName))
	
	# TODO: create a table of interactions
	# -- columns: slice index, Treg index, Fb index, total Tregs (max value of stack?)
	# -- loop through the colocresults table and collect the label column
	# -- split the label by "_" and delete objA, objB to retrieve the object indices
	# -- save this table representing each contact
	# further analysis may be best done in R
	# -- probably group by Treg ID, get total contacts per Treg
	# -- create a table of persistent contacts per Treg: total per time bin specified 
	# -- create a summary of contacts: Total Tregs , number of timepoints, number of contacts, number of persistent contacts
		
	# clean up slices
	win = wm.getWindow("coloc")
	win.close()
	TsliceImp.close()
	FsliceImp.close()
	

#row=0
#for roi in RoiManager.getInstance().getRoisAsArray():
#  a = rt.getValue("Feret", row)
#  b = rt.getValue("MinFeret", row)
#  nu= 1
#  L = 1
#  p = 1
#  s = (math.pi/4) * (1/(nu*L)) * math.pow(a, 3) * math.pow(b, 3) / (math.pow(a, 2) + math.pow(a, 2))*p
#  rt.setValue("S", row, s)
#  row = row + 1
#rt.show("Results")
