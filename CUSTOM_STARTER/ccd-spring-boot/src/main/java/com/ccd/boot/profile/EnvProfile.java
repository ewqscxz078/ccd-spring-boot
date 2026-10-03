package com.ccd.boot.profile;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.Strings;

/**
 * 提供一個已知常用 環境別名 對應 spring boot profile
 *
 */
public enum EnvProfile {
	// ================================================
	// == [Enumeration Constants] Block Start

	DEV("dev"), // 開發環境 = 本機起服務環境
	LOCAL("local"), // 本機起服務 環境
	TEST("test"), // 單元測試 環境
	SIT("sit"), // System integration testing 系統整合測試 環境
	UAT("uat"), // User Acceptance testing 使用者驗收測試 環境
	PROD("prod"),// 正式區 環境
	;

	// == [Enumeration Constants] Block End
	// ================================================
	// == [Static Variables] Block Start
	// == [Static Variables] Block Stop
	// ================================================
	// == [Instance Variables] Block Start

	private final String profile;

	// == [Instance Variables] Block Stop
	// ================================================
	// == [Static Constructor] Block Start
	// == [Static Constructor] Block Stop
	// ================================================
	// == [Constructors] Block Start (含init method)

	EnvProfile(final String profile) {
		this.profile = profile;
	}

	// == [Constructors] Block Stop
	// ================================================
	// == [Static Method] Block Start

	// 一般搭配
	// @Autowired
	// private Environment environment;
	// final String[] activeProfiles = environment.getActiveProfiles()
	// 或 web
	// final RequestContext requestContext = getRequestContext();
	// final WebApplicationContext webApplicationContext =
	// requestContext.getWebApplicationContext();
	// final Environment environment =
	// webApplicationContext.getBean(Environment.class);
	// final String[] activeProfiles = environment.getActiveProfiles(); 處理
	public static boolean isInnerTest(final String[] activeProfiles) {
		final String local = EnvProfile.LOCAL.getProfile();
		final String test = EnvProfile.TEST.getProfile();
		final String dev = EnvProfile.DEV.getProfile();

		final Set<String> innerTests = new HashSet<String>(Arrays.asList(local, test, dev));
		if (Arrays.stream(activeProfiles).anyMatch(innerTests::contains)) {
			return true;
		}
		return false;
	}

	// 依據 spring boot 設計概念 activeProfiles 可以多種 profiles
	// conditionProfile 為前端 jsp 設定的條件
	public static boolean isProfilesAnyMatch(final String[] activeProfiles, final String conditionProfile) {
		// CI/CD 設定的 SPRING_PROFILES_ACTIVE 值目前皆為小寫
		final String lowerCaseConditionProfile = StringUtils.lowerCase(conditionProfile);
		if (Arrays.stream(activeProfiles).anyMatch( //
				activeProfile -> Strings.CS.equals(activeProfile, lowerCaseConditionProfile))) {
			return true;
		}
		return false;
	}

	// public static boolean isProdAnyMatch(final String[] activeProfiles) {
	// final String prod = EnvProfile.PROD.getProfile();
	// return isAnyMatch(activeProfiles, prod);
	// }
	//
	// public static boolean isUatAnyMatch(final String[] activeProfiles) {
	// final String uat = EnvProfile.UAT.getProfile();
	// return isAnyMatch(activeProfiles, uat);
	// }
	//
	// public static boolean isSitAnyMatch(final String[] activeProfiles) {
	// final String sit = EnvProfile.SIT.getProfile();
	// return isAnyMatch(activeProfiles, sit);
	// }

	public static String getEnvProfiles(final String[] activeProfiles) {
		return StringUtils.upperCase(StringUtils.join(activeProfiles, '-'));
	}

	public static boolean isAnyMatch(final String[] activeProfiles, final String targetProfile) {
		if (Arrays.stream(activeProfiles).anyMatch(activeProfile -> {
			final boolean equals = Strings.CS.equals(activeProfile, targetProfile);
			return equals;
		})) {
			return true;
		}
		return false;
	}

	// == [Static Method] Block Stop
	// ================================================
	// == [Accessor] Block Start

	public String getProfile() {
		return this.profile;
	}

	public boolean isAnyMatch(final String[] activeProfiles) {
		if (Arrays.stream(activeProfiles).anyMatch(activeProfile -> {
			final boolean equals = Strings.CS.equals(activeProfile, this.profile);
			return equals;
		})) {
			return true;
		}
		return false;
	}

	// == [Accessor] Block Stop
	// ================================================
	// == [Overrided JDK Method] Block Start
	// == [Overrided JDK Method] Block Stop
	// ================================================
	// == [Method] Block Start
	// ####################################################################
	// ## [Method] sub-block :
	// ####################################################################
	// == [Method] Block Stop
	// ================================================
}
