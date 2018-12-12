dir = getArgument;

function vsi2tif(dir, filename) {
    print(filename+" [Exporting to tif...]");
    run("Bio-Formats Importer",
     	"open="+dir+filename+" color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack series_1");
    run("Bio-Formats Exporter",
     	   "save="+dir+filename+".tif write_each_timepoint write_each_channel export compression=Uncompressed");
    close();
    print(filename+" [DONE]");
}

setBatchMode(true);

list = getFileList(dir);
for (i = 0; i < list.length; i++)
    if (endsWith(list[i], ".vsi")) {
	vsi2tif(dir, list[i]);
    }
exit();
run("Close");
run("Quit");
eval("script", "System.exit(0);");
