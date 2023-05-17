#ifndef Header_h
#define Header_h

#import <Security/Security.h>

/*
As SecKeychainItemSetAccess() requires password in an UI prompt, we need something else that is silent in order to run it on CI.
This is a method taken from private Security API, and it does exactly the same work as SecKeychainItemSetAccess, but with password provided as an argument.
Reference: https://opensource.apple.com/source/Security/Security-58286.70.7/SecurityTool/keychain_find.c.auto.html
Idea to bridge it as a Objc header taken from https://gitlab.com/Mactroll/NoMAD/-/tree/Experimental/NoMAD.
*/
extern OSStatus SecKeychainItemSetAccessWithPassword(SecKeychainItemRef item, SecAccessRef access, UInt32 passLength, const void* password);

#endif /* Header_h */
