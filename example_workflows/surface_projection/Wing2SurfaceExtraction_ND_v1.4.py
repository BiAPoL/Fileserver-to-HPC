#@ String	(label="", value="Processing mode", visibility=MESSAGE, persist=false) dump0
#@ String	(label="process", choices={"current image", "folder"}) 		processType
#@ String	(label="filename") 		processFile
#@ ImagePlus(required=false) 											imp0
#@ File		(label="process folder", style="directory", required=false) processFolder
#@ Boolean 	(label="use roi to limit the processing region") 			useRoi
#@ Boolean 	(label="save images instead of showing?") 					saveOption
#@ File		(label="output folder", style="directory", required=false) 	outFolder

#@ String	(label="", value="Coarse detection", visibility=MESSAGE, persist=false) dump
#@ Float 	(label="downsample_factor_xy")								downsample_factor_xy
#@ Float 	(label="downsample_factor_z")								downsample_factor_z
#@ Integer 	(label="max_dz")											max_dz
#@ Float 	(label="zMap bluring")										zMapBlurringRadius

#@ String	(label="", value="Fine detection", visibility=MESSAGE, persist=false) dump2
#@ Float 	(label="downsample_factor_xy fine")							downsample_factor_xy_fine
#@ Float 	(label="downsample_factor_z fine")							downsample_factor_z_fine
#@ Integer 	(label="max_dz_fine")										max_dz_fine
#@ Float 	(label="Surface relative weigth")							relativeWeight
#@ Integer  (label="Surfaces minimum distance")							surfacesMinDistance
#@ Integer  (label="Surfaces maximum distance")							surfacesMaxDistance

#@ OpService op
#@ UIService ui


# dropped parameter from version 1.3
# Boolean	(label="Process only one surface") 							doOnlyCoarse
# Integer  (label="Number of slices around the surface") nSliceToProj
# Boolean	(label="debug") 											debug


ext = ".tif"



# Author: Benoit Lombardot, Scientific Computing Facility, MPI-CBG Dresden
# 2017-09-06, version 1
# 2017-10-20, version 1.1 add debug and do only Coarse option, make visible the zmap blurring parameter, add the surface relative weight parameter
# 2017-10-20, version 1.3.dev: revamp the projections, drop number of slice around the surface
# 2017-10-20, version 1.4: wip, batch processing

# Description:
#	the script find 2 z surfaces (zMap=f(x,y)) that goes through the highest intensity pixel in the volume
#	it outputs the 2 z maps describing the surface in the original images projecting a few slices
#	around the zSlices. The script uses a coarse to fine approach that first detection a single
#	surface with a lot of freedom on the surface altitude change (large max_dz). Then it detects 2 surface
#	in the coarsely flattened surface but with much stronger constraints on the altitude change 
#	(i.e. with a small max_dz of 1 or 2)
#
# Usage:
#	Installation: please copy MinCostZSurface_-1.1.2.jar in your Fiji plugin directory
#	To run the script on the image to analyze in Fiji. open the script in the script editor
#	and run it. A window will popup requesting parameters:
#	 - downsample_factor_xy : the ratio by which the image will be downsampled in xy (0.1 will decrease the
#		image size by 10 for instance). this factor applies to the coarse initial surface detection
#	 - downsample factor_z : the ratio by which the image will be downsampled in z (0.5 will decrease the
#		image size by 2 for instance). this factor applies to the coarse initial surface detection
#	 - max_dz : the maximum altitude change of the surface that is allowed between two neighboring pixel
#		This applies in the downsampled image used for th coarse surface detection 
#	 - downsample_factor_xy_fine : the ratio by which the image will be downsampled in xy for the
#		fine 2 surface detection step
#	 - downsample factor_z_fine : the ratio by which the image will be downsampled in z for the 
#		fine 2 surface detection step
#	 - max_dz_fine : same as max_dz for the fine 2 surface detection step
#	 - Surface minimum distance : that is the minimum distance (in pixel) that is allowed between the
#		2 detected surfaces
#	 - Number of slices around the surface : number of slices above and below the detected surfaces
#		that will be projected to give the final flattened image of the surface
#	
# Edited by ND to fix bug when running on open image, reduce projection of layer 1 to 1 above, 1 below
# Also renamed output to match that of Dagmar's, and now saves projection parameters as a text file. 



from net.imglib2.algorithm.neighborhood import CenteredRectangleShape
from net.imglib2.img.display.imagej import ImageJFunctions

from ij.plugin import Duplicator
from ij.plugin import HyperStackConverter
from ij.io import FileSaver
from ij.plugin.frame import RoiManager

from loci.plugins import BF

import time, os, math
from os.path import isfile, join

from random import randint

def main():
	IJ.log('====================')
	
	roiToProcess = None
	roiManager = RoiManager.getInstance()
	if  ( not roiManager == None )  and  roiManager.getCount()>0 :
		roiToProcess = roiManager.getRoi( roiManager.getCount()-1 )

	
	if processType == "folder" :
		
		folder = processFolder.getPath()
		files = [ f for f in os.listdir(folder) if isfile(join(folder, f)) and f.endswith(ext) ]
		for i,f in enumerate(files) :
			IJ.log('processing file '+ str(i+1) + '/' + str(len(files)) )
			imp0 = BF.openImagePlus( join(folder, f) )[0]
			imptitle = os.path.splitext(imp0.getTitle())[0]

			if (not roiToProcess == None) and useRoi :
				imp0.setRoi(roiToProcess)
				imp0 = imp0.duplicate()
			imp0.killRoi()
			
			zMap1, zMap2, project1, project2 = extractSurfaces(imp0)

			if outFolder == None: 
				saveFolder = join( folder , 'results_'+str(randint(100, 999)))
			else: 
				saveFolder = outFolder.getPath()
			# save your settings in a text: 
			filename = "settings.txt"
			with open(os.path.join(saveFolder, filename), "w") as settings: 
				settings.write("downsample_factor_xy "+str(downsample_factor_xy)+"\n")
				settings.write("downsample_factor_z "+str(downsample_factor_z)+"\n")
				settings.write("max_dz "+str(max_dz)+"\n")
				settings.write("zMapBlurringRadius "+str(zMapBlurringRadius)+"\n")
				settings.write("downsample_factor_xy_fine "+str(downsample_factor_xy_fine)+"\n")
				settings.write("downsample_factor_z_fine "+str(downsample_factor_z_fine)+"\n")
				settings.write("max_dz_fine "+str(max_dz_fine)+"\n")
				settings.write("relativeWeight "+str(relativeWeight)+"\n")
				settings.write("surfacesMinDistance "+str(surfacesMinDistance)+"\n")
				settings.write("surfacesMaxDistance "+str(surfacesMaxDistance)+"\n")
			saveResultImage( zMap1 , imptitle+"_heightMap1.tif",	saveFolder )
			saveResultImage( zMap2 , imptitle+"_heightMap0.tif",	saveFolder )
			saveResultImage( project1 , imptitle+"_projection1.tif", saveFolder )
			saveResultImage( project2 , imptitle+"_projection0.tif", saveFolder )
			
	elif processType == "current image" :

		imp0 = BF.openImagePlus( processFile )[0]
		imptitle = os.path.splitext(imp0.getTitle())[0]
		if (not roiToProcess == None) and useRoi :
				imp0.setRoi(roiToProcess)
				imp0 = imp0.duplicate()
		imp0.killRoi()
				
		zMap1, zMap2, project1, project2 = extractSurfaces( imp0 )

		if (not outFolder == None) and saveOption: 
			saveFolder = outFolder.getPath()
			saveResultImage( zMap1 , imptitle+"_heightMap1.tif",	saveFolder )
			saveResultImage( zMap2 , imptitle+"_heightMap0.tif",	saveFolder )
			saveResultImage( project1 , imptitle+"_projection1.tif", saveFolder )
			saveResultImage( project2 , imptitle+"_projection0.tif", saveFolder )
			# save your settings in a text: 
			filename = "settings_"+imptitle+".txt"
			with open(os.path.join(saveFolder, filename), "w") as settings: 
				settings.write("downsample_factor_xy "+str(downsample_factor_xy)+"\n")
				settings.write("downsample_factor_z "+str(downsample_factor_z)+"\n")
				settings.write("max_dz "+str(max_dz)+"\n")
				settings.write("zMapBlurringRadius "+str(zMapBlurringRadius)+"\n")
				settings.write("downsample_factor_xy_fine "+str(downsample_factor_xy_fine)+"\n")
				settings.write("downsample_factor_z_fine "+str(downsample_factor_z_fine)+"\n")
				settings.write("max_dz_fine "+str(max_dz_fine)+"\n")
				settings.write("relativeWeight "+str(relativeWeight)+"\n")
				settings.write("surfacesMinDistance "+str(surfacesMinDistance)+"\n")
				settings.write("surfacesMaxDistance "+str(surfacesMaxDistance)+"\n")
		
		else: 
			zMap1.show()
			zMap2.show()
			project1.show()
			project2.show()
			IJ.log("downsample_factor_xy "+str(downsample_factor_xy))
			IJ.log("downsample_factor_z "+str(downsample_factor_z))
			IJ.log("max_dz "+str(max_dz))
			IJ.log("zMapBlurringRadius "+str(zMapBlurringRadius))
			IJ.log("downsample_factor_xy_fine "+str(downsample_factor_xy_fine))
			IJ.log("downsample_factor_z_fine "+str(downsample_factor_z_fine))
			IJ.log("max_dz_fine "+str(max_dz_fine))
			IJ.log("relativeWeight "+str(relativeWeight))
			IJ.log("surfacesMinDistance "+str(surfacesMinDistance))
			IJ.log("surfacesMaxDistance "+str(surfacesMaxDistance))
			
		
	print "Surface extraction done!"





################################################
# coarse flattening of the surface (image is downsample on z)
################################################

def extractSurfaces( imp0 ):

	input = ImageJFunctions.wrap( imp0 )
	
	t00 = time.time()
	t0 = time.time()
	print ("========== Wing 2 surfaces extraction =========")
	print ("preprocessing input ...")
	cost = makeCostImage_IJ1( input )
	print ("preprocessing input done in " + str(time.time()-t0) +" seconds" )

	#if debug :
	#	show(cost, "cost image")
		
	
	# create the coarse z map of the surface
	t0 = time.time()
	print ("Processing coarse surface ..."  )
	zMap = op.run( "MinCostZSurface",	
				cost				,
				downsample_factor_xy,
				downsample_factor_z	,
				max_dz 				)
	print ("Processing coarse surface done in " + str(time.time()-t0) +" seconds")

	# smooth the zmap to correct the zmap artifact (due to the z down sampling)
	t0 = time.time()
	print ("Preparing fine surface detection..."  )
	zMap = op.filter().gauss(zMap, zMapBlurringRadius )

	# reslice the input image with the smoothed z map
	sliceAbove0 = surfacesMaxDistance
	sliceBelow0 = surfacesMaxDistance
	resliced_cost = op.run( "zMapReslice", cost  ,zMap, sliceAbove0 ,sliceBelow0 )

	print ("Preparing fine surface detection done in " + str(time.time()-t0) + " seconds"  )


	
	##########################################################
	# fine detection of the 2 surfaces
	##########################################################
	
	# create the coarse z map of the surface
	
	t0 =  time.time()
	print ("Processing fine surface detection..."  )
	#surfacesMaxDistance = resliced_cost.dimension(2)
	
	
	zMap1 , zMap2 = op.run( "MinCost2ZSurface",	
				resliced_cost				,
				downsample_factor_xy_fine	,
				downsample_factor_z_fine	,
				max_dz_fine 				,
				relativeWeight				,
				resliced_cost.dimension(2)	, # remove any constrainst for the surface max distance (rk: surfacesMaxDistance is used only for reslice)
				surfacesMinDistance			)
	print ("Processing fine surface detection done in " + str(time.time()-t0) + " seconds"  )
	

	t0 = time.time()
	print ("Preparing output ..."  )
	
	# reslice the input image with the smoothed z map
	
	zMap1 = op.filter().gauss(zMap1, 0.5/downsample_factor_xy_fine)
	zMap1 = op.filter().gauss(zMap1, zMapBlurringRadius )
	zMapFinal1 = op.math().add(zMap1,zMap)
	zMapFinal1 = op.math().add(zMapFinal1, -sliceAbove0 )

	# Changed by ND to be more precise: 
	#sliceAbove1 = surfacesMinDistance/2; 	# just above the surface (rk: zMap2 < zMap1)
	sliceAbove1 = 1; 	# just above the surface (rk: zMap2 < zMap1)	
	sliceBelow1 = 1;		# everything above the surface (rk: zMap2 < zMap1)
	resliced1 = op.run( "zMapReslice", input ,zMapFinal1, sliceAbove1 , sliceBelow1 )
	impToProj1 = ImageJFunctions.wrap(resliced1, "surface 1")
	project1 = zProject(impToProj1) # zmin=just below surface, zmax= all on top
	
	zMap2 = op.filter().gauss(zMap2, 0.5/downsample_factor_xy_fine)
	zMap2 = op.filter().gauss(zMap2, zMapBlurringRadius )
	zMapFinal2 = op.math().add(zMap2,zMap)
	zMapFinal2 = op.math().add(zMapFinal2, -sliceAbove0 )

	sliceAbove2 = surfacesMaxDistance; 		# everything below the surface (rk: zMap2 < zMap1)
	sliceBelow2 = 0; 	# just above the surface (rk: zMap2 < zMap1)	
	resliced2 = op.run( "zMapReslice", input ,zMapFinal2, sliceAbove2 ,sliceBelow2 )
	impToProj2 = ImageJFunctions.wrap(resliced2, "surface 2")
	project2 = zProject(impToProj2)

	project1.setTitle('project1_'+imp0.getTitle());
	project2.setTitle('project2_'+imp0.getTitle());
	zMapFinal1_imp = ImageJFunctions.wrap(zMapFinal1, 'zMap1_'+imp0.getTitle())
	zMapFinal2_imp = ImageJFunctions.wrap(zMapFinal2, 'zMap2_'+imp0.getTitle())

	print ("Surface extracted in " + str(time.time()-t00) + " seconds"  )
	
	return zMapFinal1_imp, zMapFinal2_imp, project1, project2



	
################################################
# helper function
################################################

# IJ2 based preprocessing : 4.5 time slower than IJ1 filtering
#from net.imglib2.algorithm.neighborhood import CenteredRectangleShape
from net.imglib2.algorithm.morphology import StructuringElements

def makeCostImage_IJ2( input ) :

	# create the cost image for the coarse
	cost = input.copy()
	# cost = op.convert().float32(cost) the code get 21 time slower than IJ1 with that conversion 
	
	cost = op.filter().gauss( cost.copy() , [0.7,0.7,0.0] )
	
	skipCenter = False
	op.filter().median(cost, cost.copy(), CenteredRectangleShape( [1,1,0] , skipCenter ) )
	
	decompose = True
	cost = op.morphology().topHat( cost.copy(), StructuringElements.rectangle([5,5,0] , decompose) )
	
	cost = op.convert().float32(cost)
	cost = op.run("multiply", cost , -1.0 )
	
	return cost



# ij1 based preprocessing

from ij import IJ

def makeCostImage_IJ1( input ) :
	
	input_imp = ImageJFunctions.wrap( input, "cost img" ) 	# the wrap gives a virtual stack image,
															# one needs to duplicate process the image
	cost_imp = input_imp.duplicate()						
		
	#IJ.run(cost_imp, "Median...", "radius=1 stack")
	#IJ.run(cost_imp, "Gaussian Blur...", "sigma=1 stack")
	#IJ.run(cost_imp, "Subtract Background...", "rolling=5 disable stack");
	IJ.run(cost_imp, "Invert", "stack")

	cost = ImageJFunctions.wrap( cost_imp )
	
	return cost


from ij.plugin import ZProjector

def zProject( imp, zMin=1, zMax=None ) :

	if zMax == None :
		zMax = imp.getStackSize()
		
	zMin = max(1,zMin) 
	zMax = min(imp.getStackSize(),zMax) 
	
	zproj = ZProjector(imp)
	zproj.setMethod(ZProjector.MAX_METHOD)
	zproj.setStartSlice(zMin)
	zproj.setStopSlice(zMax)
	zproj.doProjection()
	return zproj.getProjection()	


def show( img , title ) :
	imp = ImageJFunctions.wrap(img, title )
	imp = Duplicator().run(imp)
	
	if imp.getStackSize() > 1 :
		imp = HyperStackConverter.toHyperStack(imp, 1, imp.getStackSize(), 1, "xyctz", "Color")
	imp.setTitle( title )
	imp.show()


def saveResultImage( imp , outputName, saveFolder ):

	if not os.path.exists( saveFolder ):
		os.makedirs(saveFolder)
	FileSaver(imp).saveAsTiff( join( saveFolder, outputName ))

########################################################
# run the main() script
########################################################

main()



