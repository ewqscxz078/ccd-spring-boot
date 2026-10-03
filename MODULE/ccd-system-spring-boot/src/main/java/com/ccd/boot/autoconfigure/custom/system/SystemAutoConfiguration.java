package com.ccd.boot.autoconfigure.custom.system;

import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
// import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

import com.ccd.boot.autoconfigure.custom.system.SystemProperties.Path;

// ref spring-boot-actoconfigure
@Configuration
// 有 必要目錄
@ConditionalOnWebApplication
@EnableConfigurationProperties(SystemProperties.class)
public class SystemAutoConfiguration {

	@Bean
	@ConditionalOnMissingBean
	SystemComponent systemComponent(final SystemProperties awSystemProperties, final Environment environment) {
		final SystemComponentImpl awSystemComponentImpl = new SystemComponentImpl(environment);
		awSystemComponentImpl.setId(awSystemProperties.getId());
		awSystemComponentImpl.setDir(awSystemProperties.getDir());
		awSystemComponentImpl.setBaseDir(awSystemProperties.getBasedir());
		final Path path = awSystemProperties.getPath();
		awSystemComponentImpl.setPathConfig(path.getConfig());
		awSystemComponentImpl.setPathData(path.getData());
		awSystemComponentImpl.setPathTmp(path.getTemp());
		awSystemComponentImpl.setPathLog(path.getLog());
		return awSystemComponentImpl;
	}

}