package com.ccd.autoconfigure.custom.data.jpa;

import javax.sql.DataSource;

import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.data.jpa.autoconfigure.DataJpaRepositoriesAutoConfiguration;
import org.springframework.boot.persistence.autoconfigure.EntityScan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

import com.ccd.properties.CcdPrefixConfigurationProperties;

// ref spring-boot-actoconfigure / DataJpaRepositoriesAutoConfiguration.java
@AutoConfiguration(before = { //
		DataJpaRepositoriesAutoConfiguration.class, //
})
@ConditionalOnBean(DataSource.class)
@ConditionalOnClass(JpaRepository.class)
@ConditionalOnProperty(prefix = CcdPrefixConfigurationProperties.DATA_JPA, name = "enable", havingValue = "true", matchIfMissing = true)
public class CcdDataJpaAutoConfiguration {

	@EnableConfigurationProperties(CcdDefaultDataJpaScanProperties.class)
	// for jpa spring bean pattern
	@EnableJpaRepositories(basePackages = "#{'${ccd.data.jpa.scan.repository-scan-packages}'.split(',')}")
	// for jpa entity 同上對應路徑
	@EntityScan(basePackages = "#{'${ccd.data.jpa.scan.entity-scan-packages}'.split(',')}")
	static class CcdDefaultDataJpaScanConfiguration {
	}

}