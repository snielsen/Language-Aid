#!/usr/bin/env perl
# Copyright 2006-2011 Aoren LLC. All rights reserved.

# Clean the packages directory
`rm -Rf Packages/*.pkg`;
`rm -Rf Packages/*.dmg`;

# Copy products into the Package directories
`rm -Rf \"Packages/PackageRootDev/Library/Application Support/Language Aid/LAPlugin.h\"`;
`rm -Rf \"Packages/PackageRootDev/Library/Application Support/Language Aid/LAUserDefaults.h\"`;
`rm -Rf \"Packages/PackageRootDev/Library/Application Support/Language Aid/PluginModuleExamples\"`;
`rm -Rf \"Packages/PackageRootDev/Library/Application Support/Language Aid/Documentation\"`;
`rm -Rf \"Packages/PackageRootDev/Library/Application Support/Apple/Developer Tools/Project Templates/Language Aid\"`;
`cp \"/Library/Application Support/Language Aid/LAPlugin.h\" \"Packages/PackageRootDev/Library/Application Support/Language Aid/LAPlugin.h\"`;
`cp \"/Library/Application Support/Language Aid/LAUserDefaults.h\" \"Packages/PackageRootDev/Library/Application Support/Language Aid/LAUserDefaults.h\"`;
`cp -R \"PluginModules\" \"Packages/PackageRootDev/Library/Application Support/Language Aid/PluginModuleExamples\"`;
`rm -Rf \"Packages/PackageRootDev/Library/Application Support/Language Aid/PluginModuleExamples/MDBG\"`; # MDBG exception
`cp -R \"PluginTemplates\" \"Packages/PackageRootDev/Library/Application Support/Apple/Developer Tools/Project Templates/Language Aid\"`;
`cp -R \"Documentation\" \"Packages/PackageRootDev/Library/Application Support/Language Aid/Documentation\"`;

# Clean out all the modules build directories
opendir(DIRHANDLE,"Packages/PackageRootDev/Library/Application Support/Language Aid/PluginModuleExamples") || die "ERROR: can not read plugins directory\n"; 
foreach (readdir(DIRHANDLE))
{
	if( !($_ eq ".") && !($_ eq "..") && !($_ eq ".svn") && !($_ eq ".DS_Store") )
	{
		print "found $_\n"; 
		`rm -Rf \"Packages/PackageRootDev/Library/Application Support/Language Aid/PluginModuleExamples/$_/build\"`;
	}
}

# Make the Package
print `/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -v -ds -f Packages/PackageRootDev -i Packages/InfoDev.plist -r Packages/ResourcesDev -d Packages/DescriptionDev.plist -p Packages/LanguageAidSDK.pkg`;
`cp \"Packages/Laid logo2.tif\" Packages/LanguageAidSDK.pkg/Contents/Resources/background.tif`;
`cp Packages/WelcomeDev.rtf Packages/LanguageAidSDK.pkg/Contents/Resources/English.lproj/Welcome.rtf`;
`cp Packages/ReadMeDev.rtf Packages/LanguageAidSDK.pkg/Contents/Resources/English.lproj/ReadMe.rtf`;
`cp Packages/LicenseDev.rtf Packages/LanguageAidSDK.pkg/Contents/Resources/English.lproj/License.rtf`;
`cp Packages/LocalizableDev.strings Packages/LanguageAidSDK.pkg/Contents/Resources/English.lproj/Localizable.strings`;
`cp Packages/InstallationCheck Packages/LanguageAidSDK.pkg/Contents/Resources/InstallationCheck`;
`cp Packages/LanguageAidSDK.dist Packages/LanguageAidSDK.pkg/Contents/LanguageAidSDK.dist`;

# Create the disk image
`hdiutil create -srcfolder Packages/LanguageAidSDK.pkg -fs HFS+ -volname \"Language Aid SDK\" Packages/LanguageAidSDKA.dmg`;
`hdiutil convert -format UDCO Packages/LanguageAidSDKA.dmg -o Packages/LanguageAidSDK.dmg`;
`hdiutil unflatten Packages/LanguageAidSDK.dmg`;
#`/Developer/Tools/DeRez Packages/SLAResources > Packages/sla.r`;
#`/Developer/Tools/Rez -a Packages/sla.r -o Packages/LanguageAidSDK.dmg`;
`hdiutil internet-enable -yes Packages/LanguageAidSDK.dmg`;
`hdiutil flatten Packages/LanguageAidSDK.dmg`;
`rm Packages/LanguageAidSDKA.dmg`;
