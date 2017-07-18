macro "Threshold measurement" {
    run("8-bit");
    setAutoThreshold("Default dark");
    //run("Threshold...");
    setThreshold(42, 255);
    run("Set Measurements...",
	 "area mean min median limit display redirect=None decimal=9");
    run("Measure");
}
