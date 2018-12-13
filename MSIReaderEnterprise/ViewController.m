//
//  ViewController.m
//  Integration BCA
//
//  Created by Ravi Tej on 5/11/18.
//  Copyright © 2018 Ravi Tej. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

static NSString *errorDomain = @"CordovaPluginSharedSecret";

+ (NSDictionary *)sharedKeychainQueryFromQuery:(NSDictionary *)query andSharedAccessGroup:(NSString *)sharedAccessGroup {
    NSMutableDictionary *mutableQuery = [query mutableCopy];
    // it is only safe to use the shared keychain on a device
#if !TARGET_IPHONE_SIMULATOR
    [mutableQuery setObject:sharedAccessGroup forKey:(NSString *)kSecAttrAccessGroup];
#endif
    return mutableQuery;
}

+ (NSString *) getSecureStringForKey:(NSString *) username andServiceName:(NSString *) serviceName andSharedAccessGroup:(NSString *)sharedAccessGroup isSharedKeychain:(BOOL)isSharedKeychain clearSecret:(BOOL)clearSecret error:(NSError **) error {
    
    if (!username || !serviceName) {
        if (error != nil) {
            *error = [NSError errorWithDomain: errorDomain code: -2000 userInfo: nil];
        }
        return nil;
    }
    
    if (error != nil) {
        *error = nil;
    }
    // Set up a query dictionary with the base query attributes: item type (generic), username, and service
    NSArray *keys = [[NSArray alloc] initWithObjects: (__bridge_transfer NSString *) kSecClass, kSecAttrAccount, kSecAttrService, nil];
    NSArray *objects = [[NSArray alloc] initWithObjects: (__bridge_transfer NSString *) kSecClassGenericPassword, username, serviceName, nil];
    NSMutableDictionary *query = [[NSMutableDictionary alloc] initWithObjects: objects forKeys: keys];
    if (isSharedKeychain) {
        query = [[ViewController sharedKeychainQueryFromQuery:query andSharedAccessGroup:sharedAccessGroup] mutableCopy];
    }
    // First do a query for attributes, in case we already have a Keychain item with no password data set.
    // One likely way such an incorrect item could have come about is due to the previous (incorrect)
    // version of this code (which set the password as a generic attribute instead of password data).
    NSMutableDictionary *attributeQuery = [query mutableCopy];
    [attributeQuery setObject: (id) kCFBooleanTrue forKey:(__bridge_transfer id) kSecReturnAttributes];
    CFTypeRef attrResult = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) attributeQuery, &attrResult);
    //NSDictionary *attributeResult = (__bridge_transfer NSDictionary *)attrResult;
    if (status != noErr) {
        // No existing item found--simply return nil for the password
        if (error != nil && status != errSecItemNotFound) {
            //Only return an error if a real exception happened--not simply for "not found."
            *error = [NSError errorWithDomain: errorDomain code: status userInfo: nil];
        }
        return nil;
    }
    
    // We have an existing item, now query for the password data associated with it.
    NSMutableDictionary *passwordQuery = [query mutableCopy];
    [passwordQuery setObject: (id) kCFBooleanTrue forKey: (__bridge_transfer id) kSecReturnData];
    CFTypeRef resData = NULL;
    status = SecItemCopyMatching((__bridge CFDictionaryRef) passwordQuery, (CFTypeRef *) &resData);
    NSData *resultData = (__bridge_transfer NSData *)resData;
    if (status != noErr) {
        if (status == errSecItemNotFound) {
            // We found attributes for the item previously, but no password now, so return a special error.
            // Users of this API will probably want to detect this error and prompt the user to
            // re-enter their credentials.  When you attempt to store the re-entered credentials
            // using storeUsername:andPassword:forServiceName:updateExisting:error
            // the old, incorrect entry will be deleted and a new one with a properly encrypted
            // password will be added.
            
            if (error != nil) {
                *error = [NSError errorWithDomain: errorDomain code: -1999 userInfo: nil];
            }
        }
        else {
            // Something else went wrong. Simply return the normal Keychain API error code.
            if (error != nil) {
                *error = [NSError errorWithDomain: errorDomain code: status userInfo: nil];
            }
        }
        return nil;
    }
    NSString *password = nil;
    if (resultData) {
        password = [[NSString alloc] initWithData: resultData encoding: NSUTF8StringEncoding];
    }
    else {
        // There is an existing item, but we weren't able to get password data for it for some reason,
        // Possibly as a result of an item being incorrectly entered by the previous code.
        // Set the -1999 error so the code above us can prompt the user again.
        
        if (error != nil) {
            *error = [NSError errorWithDomain: errorDomain code: -1999 userInfo: nil];
        }
    }
    
    /*if (clearSecret) {
        [ViewController storeKey:username andSecureString:@"" andServiceName:serviceName andSharedAccessGroup:sharedAccessGroup updateExisting:TRUE isSharedKeychain:(BOOL)TRUE error:error];
    }*/
    
    return password;
}

- (IBAction)showAlert:(UIButton *)sender {
    NSLog(@"Button Pressed");
    
    NSError *theError = nil;
    
    NSString *accessGroup = @"H2ESFFMXSH.com.movencorp.b2bpartner.bca";
    NSLog(@"SharedAccessGroup=%@", accessGroup);

    NSString *token = [ViewController getSecureStringForKey:@"MovenToken"
                                         andServiceName:@"MovenWellnessSettings"
                                         andSharedAccessGroup:accessGroup
                                         isSharedKeychain:TRUE clearSecret:(BOOL)FALSE error:&theError];
    
    if (theError != nil) {
        NSLog(@"Error: %@", theError);
    }

    NSString *message = token == nil ? @"Token=(nil)" : [NSString stringWithFormat:@"Token='%@'", token];
    
    NSLog(@"%@", message);
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Done" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
    
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
