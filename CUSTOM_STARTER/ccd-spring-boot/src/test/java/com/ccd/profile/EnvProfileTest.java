package com.ccd.profile;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

import com.ccd.profile.EnvProfile;

public class EnvProfileTest {
	// ================================================
	// == [Enumeration Types] Block Start
	// == [Enumeration Types] Block End
	// ================================================
	// == [Static Variables] Block Start
	// == [Static Variables] Block Stop
	// ================================================
	// == [Instance Variables] Block Start
	// == [Instance Variables] Block Stop
	// ================================================
	// == [Static Constructor] Block Start
	// == [Static Constructor] Block Stop
	// ================================================
	// == [Constructors] Block Start (含init method)
	// == [Constructors] Block Stop
	// ================================================
	// == [Static Method] Block Start
	// == [Static Method] Block Stop
	// ================================================
	// == [Accessor] Block Start
	// == [Accessor] Block Stop
	// ================================================
	// == [Overrided JDK Method] Block Start (Ex. toString / equals+hashCode)
	// == [Overrided JDK Method] Block Stop
	// ================================================
	// == [Method] Block Start
	// ####################################################################
	// ## [Method] sub-block :
	// ####################################################################

	@Test
	public void testIsInnerTest() {
		assertTrue(EnvProfile.isInnerTest(new String[] { "local" }));
		assertTrue(EnvProfile.isInnerTest(new String[] { "dev" }));
		assertTrue(EnvProfile.isInnerTest(new String[] { "test" }));

		assertTrue(EnvProfile.isInnerTest(new String[] { "local", "db" }));
		assertTrue(EnvProfile.isInnerTest(new String[] { "dev", "db" }));
		assertTrue(EnvProfile.isInnerTest(new String[] { "dev", "db" }));

		assertFalse(EnvProfile.isInnerTest(new String[] { "sit" }));
		assertFalse(EnvProfile.isInnerTest(new String[] { "uat" }));
		assertFalse(EnvProfile.isInnerTest(new String[] { "prod" }));

		assertFalse(EnvProfile.isInnerTest(new String[] { "sit", "db" }));
		assertFalse(EnvProfile.isInnerTest(new String[] { "uat", "db" }));
		assertFalse(EnvProfile.isInnerTest(new String[] { "prod", "db" }));

		assertFalse(EnvProfile.isInnerTest(new String[] { "local2" }));
	}

	@Test
	public void testIsProfilesAnyMatch() {
		assertFalse(EnvProfile.isProfilesAnyMatch(new String[] { "local" }, "PROD"));
		assertFalse(EnvProfile.isProfilesAnyMatch(new String[] { "dev", "db" }, "PROD"));
		assertTrue(EnvProfile.isProfilesAnyMatch(new String[] { "dev" }, "DEV"));
		assertTrue(EnvProfile.isProfilesAnyMatch(new String[] { "dev" }, "dev"));
		assertTrue(EnvProfile.isProfilesAnyMatch(new String[] { "dev", "db" }, "dev"));
	}

	@Test
	public void testIsAnyMatch() {
		assertFalse(EnvProfile.PROD.isAnyMatch(new String[] { "dev", "test", "db" }));
		assertTrue(EnvProfile.PROD.isAnyMatch(new String[] { "prod", "db" }));
		assertTrue(EnvProfile.PROD.isAnyMatch(new String[] { "prod" }));

		assertFalse(EnvProfile.SIT.isAnyMatch(new String[] { "dev", "test", "db" }));
		assertTrue(EnvProfile.SIT.isAnyMatch(new String[] { "sit", "db" }));
		assertTrue(EnvProfile.SIT.isAnyMatch(new String[] { "sit" }));

		assertFalse(EnvProfile.UAT.isAnyMatch(new String[] { "dev", "test", "db" }));
		assertTrue(EnvProfile.UAT.isAnyMatch(new String[] { "uat", "db" }));
		assertTrue(EnvProfile.UAT.isAnyMatch(new String[] { "uat" }));
	}

	// == [Method] Block Stop
	// ================================================
	// == [Inner Class] Block Start
	// == [Inner Class] Block Stop
	// ================================================
}
