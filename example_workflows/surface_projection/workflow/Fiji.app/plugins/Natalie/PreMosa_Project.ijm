
Dialog.create("Tasks to be performed");
Dialog.addNumber("r: ",15);
Dialog.addNumber("d: ",2);
Dialog.addNumber("t: ",50);
Dialog.show();

r = Dialog.getNumber();
d = Dialog.getNumber();
t = Dialog.getNumber();

print(r);
print(d);
print(t);


inputdir=getDirectory("Inputdirectory");
inputfile=getString("InputName","STK_Disc_001_After_8bit.tif");
outputdir=getDirectory("Outputdirectory");
outputfile=getString("OutputName","Test8bitCOR.tif");


if (File.separator=="/" && File.exists("/home/dye/premosa/precompilesBinaries/Linux_64bit/SurfaceExtraction")){
	print("Running Corinna's Surface Extraction...");
	print("-r "+r+" -d "+d+" -t "+t+" -hmr -in "+inputdir+inputfile+" -out "+outputfile);
	exec("/home/dye/premosa/precompilesBinaries/Linux_64bit/SurfaceExtraction -r "+r+" -d "+d+" -t "+t+" -hmr -in "+inputdir+inputfile+" -out "+outputdir+outputfile);
}

else if (File.separator=="/") {print("Can't find projection program\nABORTING...");exit();} //exec("cmd /c rmdir "+folderpath+" /s/q");// Windows

print("FINISHED")
