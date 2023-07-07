//
//  SkyLight.h
//  WindowManagerExtern
//
//  Created by Yoshimasa Niwa on 7/6/23.
//

// See `Package.swift` for `-framework` linker flag.
//@import SkyLight;

extern int SLSMainConnectionID(void);
extern CFStringRef SLSCopyManagedDisplayForWindow(int connectionID, CGWindowID windowID);
