filename = getArgument;

function fitc(filename) {
    open(filename);
    run("8-bit");
    setAutoThreshold("Default dark");
    setThreshold(155, 255);
    run("Set Measurements...",
	 "area mean min median limit display redirect=None decimal=9");
    run("Measure");
}

fitc(filename);
exit();
run("Close");
run("Quit");
eval("script", "System.exit(0);");