#import "IPARUtils.h"
#include <spawn.h>
#include <signal.h>
#import "../Extensions/IPARConstants.h"
#include <sys/wait.h>
#include <unistd.h>

#define READ_END 0
#define WRITE_END 1

// global variable to store the pid of the spawned process
int spawnedProcessPid;
static NSString *pendingLoginAccountId;

@implementation IPARUtils
+ (NSDictionary *)executeCommandAndGetJSON:(NSString *)launchPath arg1:(NSString *)arg1 arg2:(NSString *)arg2 arg3:(NSString *)arg3 {
    return [self executeCommandAndGetJSON:launchPath arg1:arg1 arg2:arg2 arg3:arg3 accountId:nil];
}

+ (NSDictionary *)executeCommandAndGetJSON:(NSString *)launchPath arg1:(NSString *)arg1 arg2:(NSString *)arg2 arg3:(NSString *)arg3 accountId:(NSString *)accountId {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *launchPathValidated = kLaunchPathBash;
    #ifndef THEOS_PACKAGE_SCHEME_rootless
        if (![fileManager fileExistsAtPath:launchPath]) {
            launchPathValidated = kLaunchPathBashFallback;
        }
    #endif
    
    if (!launchPathValidated.length) {
        return @{kJsonLevel: kJsonLevelError, kJsonLevelError : @"Launch path cannot be empty" };
    }
    
    BOOL isDownload = ([arg2 containsString:@"download"]);
    
    int stdout_pipe[2];
    if (pipe(stdout_pipe) == -1) {
        return @{kJsonLevel: kJsonLevelError, kJsonLevelError : @"Failed to create pipe" };
    }

    int fileDescriptor = -1;
    if (isDownload) {
        fileDescriptor = open(kIPARangerLatestDownloadLogPath, O_CREAT | O_WRONLY | O_TRUNC, 0644);
        if (fileDescriptor == -1) {
            close(stdout_pipe[0]);
            close(stdout_pipe[1]);
            return @{kJsonLevel: kJsonLevelError, kJsonLevelError : @"Failed to open file for writing" };
        }
    }

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    
    // Redirect output
    if (isDownload) {
        posix_spawn_file_actions_adddup2(&actions, fileDescriptor, STDOUT_FILENO);
    } else {
        posix_spawn_file_actions_adddup2(&actions, stdout_pipe[1], STDOUT_FILENO);
    }

    pid_t pid;
    const char *argv[] = { [launchPathValidated UTF8String], [arg1 UTF8String], 
                          [arg2 UTF8String], [arg3 UTF8String], NULL };
    NSString *homePath = accountId.length > 0 ? [self accountHomePathForId:accountId] : [self activeAccountHomePath];
    NSString *tmpPath = [homePath stringByAppendingPathComponent:@"tmp"];
    [fileManager createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *homeEnv = [NSString stringWithFormat:@"HOME=%@", homePath];
    NSString *tmpEnv = [NSString stringWithFormat:@"TMPDIR=%@", tmpPath];
    NSString *serviceEnv = [NSString stringWithFormat:@"IPATOOL_KEYCHAIN_SERVICE=%@", [self keychainServiceForAccountId:accountId]];
    NSString *pathEnv = @"PATH=/var/jb/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    NSString *langEnv = @"LANG=en_US.UTF-8";
    char *envp[] = { (char *)[homeEnv UTF8String], (char *)[tmpEnv UTF8String], (char *)[pathEnv UTF8String], (char *)[langEnv UTF8String], (char *)[serviceEnv UTF8String], NULL };
    
    int spawnError = posix_spawn(&pid, [launchPathValidated UTF8String], &actions, NULL, 
                                (char* const*)argv, envp);
    posix_spawn_file_actions_destroy(&actions);
    
    if (spawnError != 0) {
        close(stdout_pipe[0]); 
        close(stdout_pipe[1]);
        if (isDownload) close(fileDescriptor);
        return @{kJsonLevel: kJsonLevelError, kJsonLevelError : @"Failed to spawn process" };
    }

    spawnedProcessPid = pid;
    if (isDownload) {
        close(fileDescriptor);
        close(stdout_pipe[0]);
        close(stdout_pipe[1]);
        
        return @{kJsonLevel: kJsonLevelInfo, kJsonResponseContent : @"Download started. Progress written to file."};
    }

    close(stdout_pipe[1]); 

    NSMutableData *outputData = [NSMutableData data];
    char buffer[4096];
    ssize_t bytesRead;
    
    while ((bytesRead = read(stdout_pipe[0], buffer, sizeof(buffer))) > 0) {
        [outputData appendBytes:buffer length:bytesRead];
    }
    
    close(stdout_pipe[0]); 

    waitpid(pid, NULL, 0);
    
    NSError *jsonError = nil;
    NSDictionary *jsonResult = [NSJSONSerialization JSONObjectWithData:outputData 
                                                             options:0 
                                                               error:&jsonError];

    if (jsonError) {
        return @{kJsonLevel: kJsonLevelError, kJsonLevelError : @"Failed to parse JSON output" };
    }

    return jsonResult;
}

+ (NSMutableDictionary *)settingsDictionary {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kIPARangerSettingsDict]];
    return settings;
}

+ (void)writeSettingsDictionary:(NSDictionary *)settings {
    [settings writeToFile:kIPARangerSettingsDict atomically:YES];
}

+ (NSString *)safeAccountIdFromString:(NSString *)string {
    NSString *source = string.length > 0 ? string : [[NSUUID UUID] UUIDString];
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"];
    NSMutableString *safe = [NSMutableString string];
    for (NSUInteger i = 0; i < source.length; i++) {
        unichar c = [source characterAtIndex:i];
        if ([allowed characterIsMember:c]) {
            [safe appendFormat:@"%C", c];
        }
    }
    if (safe.length == 0) {
        [safe appendString:[[NSUUID UUID] UUIDString]];
    }
    return safe;
}

+ (NSString *)accountHomePathForId:(NSString *)accountId {
    NSString *safeId = [self safeAccountIdFromString:accountId];
    return [[kIPARangerDocumentsPath stringByAppendingPathComponent:@"accounts"] stringByAppendingPathComponent:safeId];
}

+ (NSDictionary *)legacyAccountFromSettings:(NSDictionary *)settings {
    NSString *authenticated = settings[kAuthenticatedKeyFromFile];
    if (![authenticated isEqualToString:@"YES"]) {
        return nil;
    }
    NSString *accountId = @"legacy";
    NSString *email = settings[kAccountEmailKeyFromFile] ?: kUnknownValue;
    NSString *name = settings[kAccountNameKeyFromFile] ?: email;
    NSString *storefront = settings[kCountryDownloadKeyFromFile] ?: kDefaultInitialCountry;
    return @{
        kAccountIdKey: accountId,
        kAccountLabelKey: name,
        kAccountEmailKeyFromFile: email,
        kAccountNameKeyFromFile: name,
        kAccountHomeKey: [self accountHomePathForId:accountId],
        kAccountStorefrontKey: storefront,
        kAccountKeychainServiceKey: kDefaultIpatoolKeychainService
    };
}

+ (void)ensureAccountDirectory:(NSDictionary *)account {
    NSString *home = account[kAccountHomeKey];
    if (home.length > 0) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[home stringByAppendingPathComponent:@"tmp"] withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (NSArray<NSDictionary *> *)accounts {
    NSMutableDictionary *settings = [self settingsDictionary];
    NSArray *storedAccounts = settings[kAccountsKeyFromFile];
    NSMutableArray *accounts = [NSMutableArray array];
    if ([storedAccounts isKindOfClass:[NSArray class]]) {
        for (NSDictionary *account in storedAccounts) {
            if (![account isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            NSMutableDictionary *normalized = [account mutableCopy];
            NSString *accountId = normalized[kAccountIdKey];
            if (accountId.length == 0) {
                accountId = [self safeAccountIdFromString:normalized[kAccountEmailKeyFromFile]];
                normalized[kAccountIdKey] = accountId;
            }
            if (![normalized[kAccountHomeKey] length]) {
                normalized[kAccountHomeKey] = [self accountHomePathForId:accountId];
            }
            if (![normalized[kAccountKeychainServiceKey] length]) {
                normalized[kAccountKeychainServiceKey] = [accountId isEqualToString:@"legacy"] ? kDefaultIpatoolKeychainService : [NSString stringWithFormat:@"ipatool-auth-%@", accountId];
            }
            [self ensureAccountDirectory:normalized];
            [accounts addObject:normalized];
        }
    }
    if (accounts.count == 0) {
        NSDictionary *legacyAccount = [self legacyAccountFromSettings:settings];
        if (legacyAccount) {
            [self ensureAccountDirectory:legacyAccount];
            [accounts addObject:legacyAccount];
            settings[kAccountsKeyFromFile] = accounts;
            settings[kActiveAccountIdKeyFromFile] = legacyAccount[kAccountIdKey];
            [self writeSettingsDictionary:settings];
        }
    }
    return accounts;
}

+ (NSDictionary *)accountForId:(NSString *)accountId {
    for (NSDictionary *account in [self accounts]) {
        if ([account[kAccountIdKey] isEqualToString:accountId]) {
            return account;
        }
    }
    return nil;
}

+ (NSDictionary *)activeAccount {
    NSMutableDictionary *settings = [self settingsDictionary];
    NSArray *accounts = [self accounts];
    NSString *activeId = settings[kActiveAccountIdKeyFromFile];
    NSDictionary *active = [self accountForId:activeId];
    if (!active && accounts.count > 0) {
        active = accounts.firstObject;
        settings[kActiveAccountIdKeyFromFile] = active[kAccountIdKey];
        settings[kAuthenticatedKeyFromFile] = @"YES";
        settings[kAccountEmailKeyFromFile] = active[kAccountEmailKeyFromFile] ?: @"";
        settings[kAccountNameKeyFromFile] = active[kAccountNameKeyFromFile] ?: active[kAccountLabelKey] ?: @"";
        [self writeSettingsDictionary:settings];
    }
    return active;
}

+ (NSString *)activeAccountId {
    return [self activeAccount][kAccountIdKey];
}

+ (NSString *)activeAccountHomePath {
    NSDictionary *account = [self activeAccount];
    NSString *homePath = account[kAccountHomeKey];
    if (homePath.length == 0) {
        homePath = [self accountHomePathForId:@"legacy"];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:[homePath stringByAppendingPathComponent:@"tmp"] withIntermediateDirectories:YES attributes:nil error:nil];
    return homePath;
}

+ (NSString *)keychainServiceForAccountId:(NSString *)accountId {
    NSDictionary *account = accountId.length > 0 ? [self accountForId:accountId] : [self activeAccount];
    NSString *service = account[kAccountKeychainServiceKey];
    if (service.length > 0) {
        return service;
    }
    if (accountId.length > 0 && ![accountId isEqualToString:@"legacy"]) {
        return [NSString stringWithFormat:@"ipatool-auth-%@", [self safeAccountIdFromString:accountId]];
    }
    return kDefaultIpatoolKeychainService;
}

+ (NSString *)beginPendingAccountHomePath {
    pendingLoginAccountId = [NSString stringWithFormat:@"acct-%@", [[[NSUUID UUID] UUIDString] lowercaseString]];
    NSString *homePath = [self accountHomePathForId:pendingLoginAccountId];
    [[NSFileManager defaultManager] createDirectoryAtPath:[homePath stringByAppendingPathComponent:@"tmp"] withIntermediateDirectories:YES attributes:nil error:nil];
    return homePath;
}

+ (NSString *)pendingAccountId {
    return pendingLoginAccountId;
}

+ (void)cancelPendingAccount {
    if (pendingLoginAccountId.length > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:[self accountHomePathForId:pendingLoginAccountId] error:nil];
    }
    pendingLoginAccountId = nil;
}

+ (void)activateAccountWithId:(NSString *)accountId {
    NSDictionary *account = [self accountForId:accountId];
    if (!account) {
        return;
    }
    NSMutableDictionary *settings = [self settingsDictionary];
    settings[kActiveAccountIdKeyFromFile] = account[kAccountIdKey];
    settings[kAuthenticatedKeyFromFile] = @"YES";
    settings[kAccountEmailKeyFromFile] = account[kAccountEmailKeyFromFile] ?: @"";
    settings[kAccountNameKeyFromFile] = account[kAccountNameKeyFromFile] ?: account[kAccountLabelKey] ?: @"";
    [self writeSettingsDictionary:settings];
}

+ (void)addOrUpdateAccountWithEmail:(NSString *)email authName:(NSString *)authName storefront:(NSString *)storefront accountId:(NSString *)accountId {
    NSString *resolvedAccountId = accountId.length > 0 ? accountId : [self activeAccountId];
    if (resolvedAccountId.length == 0) {
        resolvedAccountId = [self safeAccountIdFromString:email];
    }
    NSMutableDictionary *settings = [self settingsDictionary];
    NSMutableArray *accounts = [[self accounts] mutableCopy];
    NSMutableDictionary *updatedAccount = nil;
    NSUInteger existingIndex = NSNotFound;
    for (NSUInteger i = 0; i < accounts.count; i++) {
        NSDictionary *account = accounts[i];
        if ([account[kAccountIdKey] isEqualToString:resolvedAccountId]) {
            updatedAccount = [account mutableCopy];
            existingIndex = i;
            break;
        }
    }
    if (!updatedAccount) {
        updatedAccount = [NSMutableDictionary dictionary];
    }
    NSString *name = authName.length > 0 ? authName : (email ?: kUnknownValue);
    updatedAccount[kAccountIdKey] = resolvedAccountId;
    updatedAccount[kAccountLabelKey] = name;
    updatedAccount[kAccountEmailKeyFromFile] = email ?: @"";
    updatedAccount[kAccountNameKeyFromFile] = name;
    updatedAccount[kAccountHomeKey] = [self accountHomePathForId:resolvedAccountId];
    updatedAccount[kAccountStorefrontKey] = storefront.length > 0 ? storefront : kDefaultInitialCountry;
    updatedAccount[kAccountKeychainServiceKey] = [resolvedAccountId isEqualToString:@"legacy"] ? kDefaultIpatoolKeychainService : [NSString stringWithFormat:@"ipatool-auth-%@", resolvedAccountId];
    [self ensureAccountDirectory:updatedAccount];
    if (existingIndex == NSNotFound) {
        [accounts addObject:updatedAccount];
    } else {
        accounts[existingIndex] = updatedAccount;
    }
    settings[kAccountsKeyFromFile] = accounts;
    settings[kActiveAccountIdKeyFromFile] = resolvedAccountId;
    settings[kAccountEmailKeyFromFile] = email ?: @"";
    settings[kAccountNameKeyFromFile] = name;
    settings[kAuthenticatedKeyFromFile] = @"YES";
    settings[kLastLoginDateKeyFromFile] = [NSDate date];
    [self writeSettingsDictionary:settings];
    pendingLoginAccountId = nil;
}

+ (void)deleteAccountWithId:(NSString *)accountId {
    if (accountId.length == 0) {
        return;
    }
    NSMutableDictionary *settings = [self settingsDictionary];
    NSMutableArray *remainingAccounts = [NSMutableArray array];
    NSDictionary *deletedAccount = nil;
    for (NSDictionary *account in [self accounts]) {
        if ([account[kAccountIdKey] isEqualToString:accountId]) {
            deletedAccount = account;
        } else {
            [remainingAccounts addObject:account];
        }
    }
    if (deletedAccount[kAccountHomeKey]) {
        [[NSFileManager defaultManager] removeItemAtPath:deletedAccount[kAccountHomeKey] error:nil];
    }
    settings[kAccountsKeyFromFile] = remainingAccounts;
    if (remainingAccounts.count > 0) {
        NSDictionary *nextAccount = remainingAccounts.firstObject;
        settings[kActiveAccountIdKeyFromFile] = nextAccount[kAccountIdKey];
        settings[kAuthenticatedKeyFromFile] = @"YES";
        settings[kAccountEmailKeyFromFile] = nextAccount[kAccountEmailKeyFromFile] ?: @"";
        settings[kAccountNameKeyFromFile] = nextAccount[kAccountNameKeyFromFile] ?: nextAccount[kAccountLabelKey] ?: @"";
    } else {
        [settings removeObjectForKey:kActiveAccountIdKeyFromFile];
        settings[kAuthenticatedKeyFromFile] = @"NO";
        settings[kAccountEmailKeyFromFile] = @"";
        settings[kAccountNameKeyFromFile] = @"";
        settings[kLastLogoutDateKeyFromFile] = [NSDate date];
    }
    [self writeSettingsDictionary:settings];
}

+ (NSString *)downloadedAccountEmailForFileName:(NSString *)fileName {
    if (fileName.length == 0) {
        return nil;
    }
    NSDictionary *downloadedAccounts = [self settingsDictionary][kDownloadedAccountsKeyFromFile];
    if (![downloadedAccounts isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSString *email = downloadedAccounts[fileName];
    return email.length > 0 ? email : nil;
}

+ (void)saveDownloadedAccountEmail:(NSString *)email forFileName:(NSString *)fileName {
    if (email.length == 0 || fileName.length == 0) {
        return;
    }
    NSMutableDictionary *settings = [self settingsDictionary];
    NSMutableDictionary *downloadedAccounts = [NSMutableDictionary dictionary];
    NSDictionary *existing = settings[kDownloadedAccountsKeyFromFile];
    if ([existing isKindOfClass:[NSDictionary class]]) {
        [downloadedAccounts addEntriesFromDictionary:existing];
    }
    downloadedAccounts[fileName] = email;
    settings[kDownloadedAccountsKeyFromFile] = downloadedAccounts;
    [self writeSettingsDictionary:settings];
}

+ (NSDictionary *)setupTaskAndPipesWithCommandposix:(NSString *)launchPath arg1:(NSString *)arg1 
  arg2:(NSString *)arg2 arg3:(NSString *)arg3 {
    int stdout_pipe[2];
    int stderr_pipe[2];
    pipe(stdout_pipe);
    pipe(stderr_pipe);
    
    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_adddup2(&actions, stdout_pipe[WRITE_END], STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&actions, stderr_pipe[WRITE_END], STDERR_FILENO);

    pid_t pid;
    const char *argv[] = { [launchPath UTF8String], [arg1 UTF8String], [arg2 UTF8String], [arg3 UTF8String], NULL };
    if (posix_spawn(&pid, [launchPath UTF8String], &actions, NULL, (char* const*)argv, NULL) != 0) {
        NSString *error = [NSString stringWithFormat:@"posix spawn failed with command: %@ %@", launchPath, arg1];
        return @{kerrorOutput: error};
    }
    
    close(stdout_pipe[WRITE_END]);
    close(stderr_pipe[WRITE_END]);

    NSArray *standardOutputArray = [NSArray array];
    NSArray *errorOutputArray = [NSArray array];
    NSData *outputData = readDataFromFD(stdout_pipe[READ_END]);
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    standardOutputArray = [outputString componentsSeparatedByString:@"\n"];
        
    NSData *errorData = readDataFromFD(stderr_pipe[READ_END]);
    NSString *errorOutput = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
    errorOutputArray = [errorOutput componentsSeparatedByString:@"\n"];
    close(stdout_pipe[READ_END]);
    close(stderr_pipe[READ_END]);

    return @{kstdOutput: standardOutputArray, kerrorOutput: errorOutputArray};
}

NSData *readDataFromFD(int fd) {
    NSMutableData *data = [[NSMutableData alloc] init];
    ssize_t count;
    char buffer[4096];
    while ((count = read(fd, buffer, sizeof(buffer))) > 0) {
        [data appendBytes:buffer length:count];
    }
    return data;
}

+ (NSDictionary<NSString*,NSArray*> *)setupTaskAndPipesWithCommand:(NSString *)command {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:kLaunchPathBash];
    [task setArguments:@[kBashCommandKey, command]];
    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardError:errorPipe];
    [task setStandardOutput:outputPipe];
    [task launch];

    NSArray *standardOutputArray = [NSArray array];
    NSArray *errorOutputArray = [NSArray array];
    spawnedProcessPid = task.processIdentifier;

    if ([command containsString:@"download"]) {
       [[errorPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
       [[outputPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
    } else {
        NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        standardOutputArray = [outputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        NSString *errorOutput = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
        errorOutputArray = [errorOutput componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    }
    return @{kstdOutput: standardOutputArray, kerrorOutput: errorOutputArray};
}

+ (void)setupUnzipTask:(NSString *)ipaFilePath directoryPath:(NSString *)directoryPath file:(NSString *)fileToUnzip {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:kLaunchPathUnzip];
    [task setArguments:@[ipaFilePath, [NSString stringWithFormat:@"Payload/*.app/%@", fileToUnzip]]];
    task.currentDirectoryPath = directoryPath;
    [task launch];
    [task waitUntilExit];
}

+ (NSString *)sha256ForFileAtPath:(NSString *)filePath {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (handle == nil) {
        return nil;
    }
    
    CC_SHA256_CTX sha256;
    CC_SHA256_Init(&sha256);

    BOOL done = NO;
    while (!done) {
        NSData *fileData = [handle readDataOfLength:256];
        CC_SHA256_Update(&sha256, [fileData bytes], (CC_LONG)[fileData length]);
        if ([fileData length] == 0) {
            done = YES;
        }
    }

    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &sha256);

    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];

    return output;
}

+ (id)getKeyFromFile:(NSString *)key defaultValueIfNil:(NSString *)defaultValue {
    NSMutableDictionary *settings = [self settingsDictionary];
    if ([key isEqualToString:kAuthenticatedKeyFromFile]) {
        NSArray *storedAccounts = settings[kAccountsKeyFromFile];
        if ([storedAccounts isKindOfClass:[NSArray class]] && storedAccounts.count > 0) {
            return @"YES";
        }
    }
    return settings[key] ? settings[key] : defaultValue;
}

+ (void)saveKeyToFile:(NSString *)key withValue:(NSString *)value {
    NSMutableDictionary *settings = [self settingsDictionary];
    settings[key] = value;
    [self writeSettingsDictionary:settings];
    //post a notification once we save a country
    if ([[key lowercaseString] containsString:@"country"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kIPARCountryChangedNotification object:nil];
    }
}

+ (void)accountDetailsToFile:(NSString *)userEmail authName:(NSString *)authName authenticated:(NSString *)authenticated {
    NSMutableDictionary *settings = [self settingsDictionary];
    settings[kAccountEmailKeyFromFile] = userEmail;
    settings[kAccountNameKeyFromFile] = authName;
    settings[kAuthenticatedKeyFromFile] = authenticated;
    if ([authenticated isEqualToString:@"NO"]) {
        settings[kLastLogoutDateKeyFromFile] = [NSDate date];
    } else {
        settings[kLastLoginDateKeyFromFile] = [NSDate date];
    }
    [self writeSettingsDictionary:settings];
}

+ (NSString *)emojiFlagForISOCountryCode:(NSString *)countryCode {
    //our fallback country
    if (countryCode.length != 2) {
        countryCode = kDefaultInitialCountry;
    }

    int base = 127462 -65;

    wchar_t bytes[2] = {
        base +[countryCode characterAtIndex:0],
        base +[countryCode characterAtIndex:1]
    };

    return [[NSString alloc] initWithBytes:bytes length:countryCode.length *sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
}

+ (UIButton *)createButtonWithImageName:(NSString *)imageName title:(NSString *)title fontSize:(CGFloat)fontSize selectorName:(NSString *)selectorName frame:(CGRect)frame {
    SEL selector = NSSelectorFromString(selectorName);
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [button sizeToFit];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setImageEdgeInsets:UIEdgeInsetsMake(0, -30, 0, 0)]; // shift image left by 10 points
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)]; // shift text right by 10 points
    return button;
}

+ (void)openTW {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:kTwitterLink];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

+ (void)openPP {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:kPaypalLink];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

+ (void)openGithub {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:kGithubRepoLink];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

+ (void)getAppIconFromApple:(NSString *)bundleId completion:(void (^)(UIImage *appIcon))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kItunesImagesForBundleURL, bundleId]];
        NSData *data = [NSData dataWithContentsOfURL:url];

        UIImage *iconImage = nil;

        if (data) {
            NSError *jsonError = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];

            if (!jsonError) {
                NSArray *results = json[@"results"];
                if (results.count > 0) {
                    NSDictionary *appInfo = results[0];
                    NSString *iconUrlString = appInfo[kItunesImagesForBundleAnswerField];
                    NSURL *iconUrl = [NSURL URLWithString:iconUrlString];
                    NSData *iconData = [NSData dataWithContentsOfURL:iconUrl];

                    if (iconData) {
                        iconImage = [UIImage imageWithData:iconData];
                    }
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(iconImage);
            }
        });
    });
}

+ (NSString *)humanReadableSizeForBytes:(long long)bytes {
    NSArray *suffixes = @[@"B", @"KB", @"MB", @"GB"];
    int suffixIndex = 0;
    double size = (double)bytes;
    
    while (size > 1024 && suffixIndex < suffixes.count - 1) {
        size /= 1024;
        suffixIndex++;
    }
    
    NSString *sizeString = [NSString stringWithFormat:@"%.1f %@", size, suffixes[suffixIndex]];
    return sizeString;
}

+ (void)animateClickOnCell:(UITableViewCell *)cell {
    [UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        cell.transform = CGAffineTransformMakeScale(0.90, 0.90);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            cell.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

+ (void)presentDialogWithTitle:(NSString *)title 
                    message:(NSString *)message
                    hasTextfield:(BOOL)hasTextfield
                    withTextfieldBlock:(AlertTextFieldBlock)textFieldBlock
                    alertConfirmationBlock:(AlertActionBlockWithTextField)confirmationBlock
                    withConfirmText:(NSString *)confirmText
                    alertCancelBlock:(AlertActionBlock)cancelBlock
                    withCancelText:(NSString *)cancelText
                    presentOn:(id)viewController {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    if (hasTextfield == YES) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textFieldBlock(textField);
        }];
    }
    if ([confirmText length] != 0) {
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (confirmationBlock != nil) {
                if (hasTextfield == YES) {
                    confirmationBlock(alert.textFields.firstObject);
                } else {
                    confirmationBlock(nil);
                }
            }
        }];
        [alert addAction:confirmAction];
    }

    if ([cancelText length] != 0) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelText style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (cancelBlock != nil) {
                cancelBlock();
            }
        }];
        [alert addAction:cancelAction];
    }
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (UIActivityIndicatorView *)createActivitiyIndicatorWithPoint:(CGPoint)point {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.center = point;
    spinner.color = [UIColor grayColor];
    [spinner startAnimating];
    return spinner;
}

+ (unsigned long long)calculateFolderSize:(NSString *)folderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:folderPath]) {
        return 0;
    }

    NSArray *contents = [fileManager contentsOfDirectoryAtPath:folderPath error:&error];
    if (error) {
        return 0;
    }

    unsigned long long folderSize = 0;
    for (NSString *item in contents) {
        NSString *itemPath = [folderPath stringByAppendingPathComponent:item];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:itemPath error:&error];
        if (error) {
            continue;
        }
        
        if ([[attributes fileType] isEqualToString:NSFileTypeDirectory]) {
            folderSize += [self calculateFolderSize:itemPath];
        } else {
            folderSize += [attributes fileSize];
        }
    }
    
    return folderSize;
}

+ (void)cancelScript {
    kill(spawnedProcessPid, SIGKILL);
}
@end
