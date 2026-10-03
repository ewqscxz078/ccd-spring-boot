package com.ccd.autoconfigure.custom.data.jpa;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "ccd.data.jpa")
public class CcdDataJpaProperties {

	private boolean enable;

	public boolean isEnable() {
		return this.enable;
	}

	public void setEnable(final boolean enable) {
		this.enable = enable;
	}

}
