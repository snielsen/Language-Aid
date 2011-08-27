#!/usr/bin/env perl
# Copyright 2006-2011 Aoren LLC. All rights reserved.

# Clean and build

#$CONFIG = $ARGV[0];
$CONFIG = "Release";

`rm -R "/Library/Application Support/Language Aid/"*`;

print `xcodebuild clean -target all -configuration $CONFIG`;
system("xcodebuild build -target all -configuration $CONFIG");

# Clean the packages directory
`rm -Rf Packages/*.pkg`;
`rm -Rf Packages/*.dmg`;

# Build all of the plugin modules
`rm -Rf \"Packages/PackageRoot/Library/Application Support/Language Aid/PluginModules/*\"`;
`rm -Rf \"/Library/Application Support/Language Aid/PluginModules/\"`;

#`mkdir -p \"Packages/PackageRoot/Library/Application Support/Language Aid/PluginModules/\"`;
`mkdir -p \"/Library/Application Support/Language Aid/PluginModules/\"`;

opendir(DIRHANDLE,"PluginModules") || die "ERROR: can not read plugins directory\n"; 
foreach (readdir(DIRHANDLE))
{
	if( !($_ eq ".") && !($_ eq "..") && !($_ eq ".svn") && !($_ eq ".DS_Store") )
	{
		print "found $_\n"; 
	
		chdir("PluginModules/$_");
	
		print `xcodebuild clean -configuration $CONFIG`;
		system("xcodebuild build -configuration $CONFIG");
				
		`cp -R \"build/$CONFIG/$_.laplugin\" \"../../Packages/PackageRoot/Library/Application Support/Language Aid/PluginModules/\"`;
		
		chdir("../../");
	}
}

`chmod g+w \"Packages/PackageRoot/Library/Application Support/Language Aid/PluginModules\"`;
`chgrp admin \"Packages/PackageRoot/Library/Application Support/Language Aid/PluginModules\"`;

# Copy products into the Package directories
`rm -R \"Packages/PackageRoot/Library/Application Support/Language Aid/Language Aid.app\"`;
`rm -R \"Packages/PackageRoot/Library/PreferencePanes/Language Aid.prefPane\"`;
`rm -R \"Packages/PackageRoot/Library/Contextual Menu Items/LanguageAidCMI.plugin\"`;
`cp -R \"build/$CONFIG/Language Aid.app\" \"Packages/PackageRoot/Library/Application Support/Language Aid/Language Aid.app\"`;
`cp -R \"build/$CONFIG/Language Aid.prefPane\" \"Packages/PackageRoot/Library/PreferencePanes/Language Aid.prefPane\"`;
`cp -R \"build/$CONFIG/LanguageAidCMI.plugin\" \"Packages/PackageRoot/Library/Contextual Menu Items/LanguageAidCMI.plugin\"`;

# Make the Package
print `/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -v -ds -f Packages/PackageRoot -i Packages/Info.plist -r Packages/Resources -d Packages/Description.plist -p Packages/LanguageAid.pkg`;
`mkdir Packages/LanguageAid.pkg/Contents/Resources/English.lproj`;
`mv Packages/LanguageAid.pkg/Contents/Resources/en.lproj/Description.plist Packages/LanguageAid.pkg/Contents/Resources/English.lproj/Description.plist`;
`rm -rf Packages/LanguageAid.pkg/Contents/Resources/en.lproj`;
`cp \"Packages/Laid logo2.tif\" Packages/LanguageAid.pkg/Contents/Resources/background.tif`;
`cp Packages/Welcome.rtf Packages/LanguageAid.pkg/Contents/Resources/English.lproj/Welcome.rtf`;
`cp Packages/ReadMe.rtf Packages/LanguageAid.pkg/Contents/Resources/English.lproj/ReadMe.rtf`;
`cp Packages/License.rtf Packages/LanguageAid.pkg/Contents/Resources/English.lproj/License.rtf`;
`cp Packages/Localizable.strings Packages/LanguageAid.pkg/Contents/Resources/English.lproj/Localizable.strings`;
`cp Packages/InstallationCheck Packages/LanguageAid.pkg/Contents/Resources/InstallationCheck`;
`cp Packages/LanguageAid.dist Packages/LanguageAid.pkg/Contents/LanguageAid.dist`;

# Create the disk image
`hdiutil create -srcfolder Packages/LanguageAid.pkg -fs HFS+ -volname \"Language Aid\" Packages/LanguageAidA.dmg`;
`hdiutil convert -format UDCO Packages/LanguageAidA.dmg -o Packages/LanguageAid.dmg`;
`hdiutil unflatten Packages/LanguageAid.dmg`;
#`/Developer/Tools/DeRez Packages/SLAResources > Packages/sla.r`;
#`/Developer/Tools/Rez -a Packages/sla.r -o Packages/LanguageAid.dmg`;
`hdiutil internet-enable -yes Packages/LanguageAid.dmg`;
`hdiutil flatten Packages/LanguageAid.dmg`;
`rm Packages/LanguageAidA.dmg`;

`mv Packages/LanguageAid.dmg \"Packages/LanguageAid - $CONFIG.dmg\"`;
