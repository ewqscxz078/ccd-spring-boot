package com.ccd.system;

import org.springframework.core.env.Environment;

import com.ccd.twse.profile.EnvProfile;

// import tw.gov.moi.aw3.profile.EnvProfile;

/**
 *
 */
public class SystemComponentImpl implements SystemComponent {

	// ================================================
	// == [Enumeration Types] Block Start
	// == [Enumeration Types] Block End
	// ================================================
	// == [Static Variables] Block Start
	// == [Static Variables] Block Stop
	// ================================================
	// == [Instance Variables] Block Start

	private String id;

	private String dir;

	private String baseDir;

	private String pathConfig;

	private String pathData;

	private String pathTmp;

	private String pathLog;

	private final Environment environment;

	// == [Instance Variables] Block Stop
	// ================================================
	// == [Static Constructor] Block Start
	// == [Static Constructor] Block Stop
	// ================================================
	// == [Constructors] Block Start (含init method)

	/**
	 * @param environment
	 */
	public SystemComponentImpl(final Environment environment) {
		this.environment = environment;
	}

	// == [Constructors] Block Stop
	// ================================================
	// == [Static Method] Block Start
	// == [Static Method] Block Stop
	// ================================================
	// == [Accessor] Block Start

	@Override
	public String getId() {
		return this.id;
	}

	@Override
	public String getDir() {
		return this.dir;
	}

	@Override
	public String getBaseDir() {
		return this.baseDir;
	}

	@Override
	public String getPathConfig() {
		return this.pathConfig;
	}

	@Override
	public String getPathData() {
		return this.pathData;
	}

	@Override
	public String getPathTmp() {
		// TODO profile local 取得相對路徑後的絕對路徑
		return this.pathTmp;
	}

	@Override
	public String getPathLog() {
		// TODO profile local 取得相對路徑後的絕對路徑
		return this.pathLog;
	}

	// ####################################################################
	// ## [Accessor] sub-block : set by autoConfiguration
	// ####################################################################

	public void setId(final String id) {
		this.id = id;
	}

	public void setDir(final String dir) {
		this.dir = dir;
	}

	public void setBaseDir(final String baseDir) {
		this.baseDir = baseDir;
	}

	public void setPathConfig(final String pathConfig) {
		this.pathConfig = pathConfig;
	}

	public void setPathData(final String pathData) {
		this.pathData = pathData;
	}

	public void setPathTmp(final String pathTmp) {
		this.pathTmp = pathTmp;
	}

	public void setPathLog(final String pathLog) {
		this.pathLog = pathLog;
	}

	// == [Accessor] Block Stop
	// ================================================
	// == [Overrided JDK Method] Block Start (Ex. toString / equals+hashCode)
	// == [Overrided JDK Method] Block Stop
	// ================================================
	// == [Method] Block Start
	// ####################################################################
	// ## [Method] sub-block :
	// ####################################################################

	@Override
	public boolean isProfile(final String profile) {
		final String[] activeProfiles = this.environment.getActiveProfiles();
		return EnvProfile.isAnyMatch(activeProfiles, profile);
	}

	public String getEnvProfiles() {
		final String[] activeProfiles = this.environment.getActiveProfiles();
		// 一般來說是 LOCAL、SIT、UAT、PROD、TEST
		// 若有多個 profiles 則會回 profile1-profiles2 的大寫回傳
		return EnvProfile.getEnvProfiles(activeProfiles);
	}

	// public boolean isProd() {
	// final String[] activeProfiles = this.environment.getActiveProfiles();
	// return EnvProfile.PROD.isAnyMatch(activeProfiles);
	// }
	//
	// public boolean isUat() {
	// final String[] activeProfiles = this.environment.getActiveProfiles();
	// return EnvProfile.UAT.isAnyMatch(activeProfiles);
	// }
	//
	// public boolean isSit() {
	// final String[] activeProfiles = this.environment.getActiveProfiles();
	// return EnvProfile.SIT.isAnyMatch(activeProfiles);
	// }

	public boolean isDev() {
		final String[] activeProfiles = this.environment.getActiveProfiles();
		return EnvProfile.isInnerTest(activeProfiles);
	}

	// == [Method] Block Stop
	// ================================================
	// == [Inner Class] Block Start
	// == [Inner Class] Block Stop
	// ================================================
}
