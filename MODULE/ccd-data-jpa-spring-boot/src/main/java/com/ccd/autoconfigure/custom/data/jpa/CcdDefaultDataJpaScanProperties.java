package com.ccd.autoconfigure.custom.data.jpa;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "ccd.data.jpa.scan")
public class CcdDefaultDataJpaScanProperties {

	private boolean enable;

	// 多個請用,分隔
	private String entityPackages;

	// 多個請用,分隔
	private String repositoryPackages;

	public boolean isEnable() {
		return this.enable;
	}

	public void setEnable(final boolean enable) {
		this.enable = enable;
	}

	public String getEntityPackages() {
		return this.entityPackages;
	}

	public void setEntityPackages(final String entityPackages) {
		this.entityPackages = entityPackages;
	}

	public String getRepositoryPackages() {
		return this.repositoryPackages;
	}

	public void setRepositoryPackages(final String repositoryPackages) {
		this.repositoryPackages = repositoryPackages;
	}

}
