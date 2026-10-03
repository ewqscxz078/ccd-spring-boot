package com.ccd.boot.autoconfigure.custom.system;

public interface SystemComponent {
	public String getId();

	public String getDir();

	public String getBaseDir();

	public String getPathConfig();

	public String getPathData();

	public String getPathTmp();

	public String getPathLog();

	public boolean isProfile(String profile);
}
