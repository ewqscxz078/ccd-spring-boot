package com.ccd.autoconfigure.custom.system;

import java.util.Locale;
import java.util.UUID;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("ccd.system")
public class SystemProperties {

	// ================================================
	// == [Enumeration Types] Block Start
	// == [Enumeration Types] Block End
	// ================================================
	// == [Static Variables] Block Start
	// == [Static Variables] Block Stop
	// ================================================
	// == [Instance Variables] Block Start

	private String id = UUID.randomUUID().toString();

	private String dir = UUID.randomUUID().toString().toUpperCase(Locale.ENGLISH);

	private String basedir = "../CONFIG";

	private final Path path = new Path(this.basedir, this.dir);

	// == [Instance Variables] Block Stop
	// ================================================
	// == [Static Constructor] Block Start

	public static class Path {

		public Path(final String basedir, final String dir) {
			this.config = basedir + "/" + dir + "/config";
			this.resource = basedir + "/" + dir + "/resource";
			this.data = basedir + "/" + dir + "/data";
			this.temp = basedir + "/" + dir + "/temp";
			this.log = basedir + "/" + dir + "/log";
		}

		private String config; // {basedir}/{dir}/config option
		private String resource; // {basedir}/{dir}/resource option
		private String data; // {basedir}/{dir}/data option 永久存放
		private String temp; // {basedir}/{dir}/temp 暫存處理資料:通常會有且要有對應清除機制
		private String log; // {basedir}/{dir}/log 一定有

		public String getConfig() {
			return this.config;
		}

		public void setConfig(final String config) {
			this.config = config;
		}

		public String getResource() {
			return this.resource;
		}

		public void setResource(final String resource) {
			this.resource = resource;
		}

		public String getData() {
			return this.data;
		}

		public void setData(final String data) {
			this.data = data;
		}

		public String getTemp() {
			return this.temp;
		}

		public void setTemp(final String temp) {
			this.temp = temp;
		}

		public String getLog() {
			return this.log;
		}

		public void setLog(final String log) {
			this.log = log;
		}

	}

	// == [Static Constructor] Block Stop
	// ================================================
	// == [Constructors] Block Start (含init method)
	// == [Constructors] Block Stop
	// ================================================
	// == [Static Method] Block Start
	// == [Static Method] Block Stop
	// ================================================
	// == [Accessor] Block Start

	public String getId() {
		return this.id;
	}

	public void setId(final String id) {
		this.id = id;
	}

	public String getDir() {
		return this.dir;
	}

	public void setDir(final String dir) {
		this.dir = dir;
	}

	public String getBasedir() {
		return this.basedir;
	}

	public void setBasedir(final String basedir) {
		this.basedir = basedir;
	}

	public Path getPath() {
		return this.path;
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
	// == [Method] Block Stop
	// ================================================
	// == [Inner Class] Block Start
	// == [Inner Class] Block Stop
	// ================================================

}
