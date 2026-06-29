#import "IPARAccountAndCreditsController.h"
#import "IPARLoginScreenViewController.h"
#import "IPARSearchViewController.h"
#import "IPARDownloadViewController.h"
#import "../Extensions/IPARConstants.h"
#import "../Utils/IPARUtils.h"

//those are the only one gets referenced later on
@interface IPARAccountAndCredits ()
@property (nonatomic) UILabel *searchCountryLabel;
@property (nonatomic) UILabel *downloadCountryLabel;
@property (nonatomic) UILabel *accountNameLabel;
@property (nonatomic) UILabel *emailLabel;
@end

@implementation IPARAccountAndCredits
- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = kAccountTitle;
		self.tabBarItem.image = [UIImage systemImageNamed:kPersonIcon];
		self.tabBarItem.title = kAccountTitle;
    }
    return self;
}

- (void)loadView {
    [super loadView];

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:scrollView];
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 800)];
    [scrollView addSubview:contentView];
    scrollView.contentSize = contentView.frame.size;

    UIView *headerView = [self setupHeaderView];
    [contentView addSubview:headerView];

    UIImageView *headerImageView = [self setupHeaderImage];
    [contentView addSubview:headerImageView];

    NSDictionary *activeAccount = [IPARUtils activeAccount];
    self.accountNameLabel = [self createLabelWithText:activeAccount[kAccountNameKeyFromFile] ?: [IPARUtils getKeyFromFile:kAccountNameKeyFromFile defaultValueIfNil:kUnknownValue] fontSize:17.0];
    UILabel *accountNameLabel = self.accountNameLabel;
    [contentView addSubview:accountNameLabel];

    self.emailLabel = [self createLabelWithText:activeAccount[kAccountEmailKeyFromFile] ?: [IPARUtils getKeyFromFile:kAccountEmailKeyFromFile defaultValueIfNil:kUnknownValue] fontSize:17.0];
    UILabel *emailLabel = self.emailLabel;
    [contentView addSubview:emailLabel];

    UIButton *logoutButton = [self setupLogoutButton];
    [contentView addSubview:logoutButton];

    UIButton *addAccountButton = [self setupAccountButtonWithTitle:@"Add Account" selector:@selector(handleAddAccount)];
    [contentView addSubview:addAccountButton];

    UIButton *switchAccountButton = [self setupAccountButtonWithTitle:@"Switch Account" selector:@selector(handleSwitchAccount)];
    [contentView addSubview:switchAccountButton];

    NSString *formattedDate = [self setupDateFomatter];
    UILabel *lastLoginDate = [self createLabelWithText:[NSString stringWithFormat:@"Login Date: %@", formattedDate] fontSize:17.0];
    [contentView addSubview:lastLoginDate];

    NSString *searchCountry = [IPARUtils getKeyFromFile:kCountrySearchKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
    self.searchCountryLabel = [self createLabelWithText:kipaToolVersion fontSize:17.0];
    [contentView addSubview:self.searchCountryLabel];

    NSString *downloadCountry = [IPARUtils getKeyFromFile:kCountryDownloadKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
    self.downloadCountryLabel = [self createLabelWithText:kIPARangerVersion fontSize:17.0];
    [contentView addSubview:self.downloadCountryLabel];

    UILabel *createdByLabel = [self createLabelWithText:@"Created by 0xkuj" fontSize:24];
    [contentView addSubview:createdByLabel];

    UIButton *followMeTwitter = [IPARUtils createButtonWithImageName:kTwitterIcon title:@"Follow Me On Twitter" fontSize:16.0 selectorName:@"openTW" frame:CGRectMake(0,0,150,50)];
    [contentView addSubview:followMeTwitter];

    UIButton *buyMeCoffeePP = [IPARUtils createButtonWithImageName:kPaypalIcon title:@"Buy me a coffee" fontSize:16.0 selectorName:@"openPP" frame:CGRectMake(0,0,300,50)];
    [contentView addSubview:buyMeCoffeePP];

    UIButton *followMeGithub = [IPARUtils createButtonWithImageName:kGithubIcon title:@"Source Code" fontSize:16.0 selectorName:@"openGithub" frame:CGRectMake(0,0,150,50)];
    [contentView addSubview:followMeGithub];

    UILabel *credits = [self createLabelWithText:@"Special Thanks" fontSize:24.0];
    [contentView addSubview:credits];

    UILabel *majdLabel = [self createLabelWithText:@"Majd Alfhaily (ipatool)" fontSize:14.0];
    [contentView addSubview:majdLabel];

    UILabel *angelXwindLabel = [self createLabelWithText:@"angelXwind (appinst)" fontSize:14.0];
    [contentView addSubview:angelXwindLabel];

    accountNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    emailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    logoutButton.translatesAutoresizingMaskIntoConstraints = NO;
    addAccountButton.translatesAutoresizingMaskIntoConstraints = NO;
    switchAccountButton.translatesAutoresizingMaskIntoConstraints = NO;
    lastLoginDate.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchCountryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.downloadCountryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    createdByLabel.translatesAutoresizingMaskIntoConstraints = NO;
    followMeTwitter.translatesAutoresizingMaskIntoConstraints = NO;
    buyMeCoffeePP.translatesAutoresizingMaskIntoConstraints = NO;
    followMeGithub.translatesAutoresizingMaskIntoConstraints = NO;
    credits.translatesAutoresizingMaskIntoConstraints = NO;
    majdLabel.translatesAutoresizingMaskIntoConstraints = NO;
    angelXwindLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        // Header image constraints
        [headerImageView.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor],
        [headerImageView.topAnchor constraintEqualToAnchor:headerView.safeAreaLayoutGuide.topAnchor constant:16],
        [headerImageView.widthAnchor constraintEqualToConstant:80],
        [headerImageView.heightAnchor constraintEqualToConstant:80],
        
        // Account info constraints
        [accountNameLabel.topAnchor constraintEqualToAnchor:headerImageView.bottomAnchor constant:16],
        [accountNameLabel.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        
        [emailLabel.topAnchor constraintEqualToAnchor:accountNameLabel.bottomAnchor constant:8],
        [emailLabel.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        
        // Logout button constraints - positioned below email
        [logoutButton.topAnchor constraintEqualToAnchor:emailLabel.bottomAnchor constant:24],
        [logoutButton.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [logoutButton.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [logoutButton.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [logoutButton.heightAnchor constraintEqualToConstant:50],

        [addAccountButton.topAnchor constraintEqualToAnchor:logoutButton.bottomAnchor constant:14],
        [addAccountButton.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [addAccountButton.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [addAccountButton.heightAnchor constraintEqualToConstant:44],

        [switchAccountButton.topAnchor constraintEqualToAnchor:addAccountButton.bottomAnchor constant:10],
        [switchAccountButton.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:20],
        [switchAccountButton.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-20],
        [switchAccountButton.heightAnchor constraintEqualToConstant:44],
        
        // Info labels constraints
        [lastLoginDate.topAnchor constraintEqualToAnchor:switchAccountButton.bottomAnchor constant:24],
        [lastLoginDate.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:16],
        
        [self.searchCountryLabel.topAnchor constraintEqualToAnchor:lastLoginDate.bottomAnchor constant:16],
        [self.searchCountryLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:16],
        
        [self.downloadCountryLabel.topAnchor constraintEqualToAnchor:self.searchCountryLabel.bottomAnchor constant:16],
        [self.downloadCountryLabel.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:16],
        
        // Created by section
        [createdByLabel.topAnchor constraintEqualToAnchor:self.downloadCountryLabel.bottomAnchor constant:32],
        [createdByLabel.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        
        // Social links constraints
        [followMeTwitter.topAnchor constraintEqualToAnchor:createdByLabel.bottomAnchor constant:16],
        [followMeTwitter.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [buyMeCoffeePP.topAnchor constraintEqualToAnchor:followMeTwitter.bottomAnchor constant:16],
        [buyMeCoffeePP.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [followMeGithub.topAnchor constraintEqualToAnchor:buyMeCoffeePP.bottomAnchor constant:16],
        [followMeGithub.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        // Credits constraints
        [credits.topAnchor constraintEqualToAnchor:followMeGithub.bottomAnchor constant:32],
        [credits.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [majdLabel.topAnchor constraintEqualToAnchor:credits.bottomAnchor constant:8],
        [majdLabel.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [angelXwindLabel.topAnchor constraintEqualToAnchor:majdLabel.bottomAnchor constant:8],
        [angelXwindLabel.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [angelXwindLabel.bottomAnchor constraintLessThanOrEqualToAnchor:contentView.bottomAnchor constant:-20],
    ]];
    
    // deprecated
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCountry) name:kIPARCountryChangedNotification object:nil];
}


- (CAGradientLayer *)setupGradientLayer {
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, -100, self.view.frame.size.width, 900);

    if (@available(iOS 13.0, *)) {
        BOOL isDarkMode = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
        if (isDarkMode) {
            gradientLayer.colors = @[
                (id)[UIColor colorWithRed:30/255.0 green:45/255.0 blue:70/255.0 alpha:1.0].CGColor,   
                (id)[UIColor colorWithRed:15/255.0 green:25/255.0 blue:45/255.0 alpha:1.0].CGColor,  
                (id)[UIColor colorWithRed:8/255.0 green:12/255.0 blue:25/255.0 alpha:1.0].CGColor     
            ];
        } else {
            gradientLayer.colors = @[
                (id)[UIColor colorWithRed:220/255.0 green:230/255.0 blue:250/255.0 alpha:1.0].CGColor,   
                (id)[UIColor colorWithRed:200/255.0 green:210/255.0 blue:230/255.0 alpha:1.0].CGColor,  
                (id)[UIColor colorWithRed:180/255.0 green:190/255.0 blue:215/255.0 alpha:1.0].CGColor     
            ];
        }
    } else {
            gradientLayer.colors = @[
                (id)[UIColor colorWithRed:220/255.0 green:230/255.0 blue:250/255.0 alpha:1.0].CGColor,   
                (id)[UIColor colorWithRed:200/255.0 green:210/255.0 blue:230/255.0 alpha:1.0].CGColor,  
                (id)[UIColor colorWithRed:180/255.0 green:190/255.0 blue:215/255.0 alpha:1.0].CGColor     
            ];
    }

    gradientLayer.locations = @[@0.0, @0.65, @1.0];
    gradientLayer.startPoint = CGPointMake(0.4, 0.0);
    gradientLayer.endPoint = CGPointMake(0.6, 1.0);

    return gradientLayer;
}

- (NSString *)setupDateFomatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:kDateFormatter];
    NSDate *date = [IPARUtils getKeyFromFile:kLastLoginDateKey defaultValueIfNil:kUnknownValue];
    NSString *formattedDate = [dateFormatter stringFromDate:date];
    return formattedDate;
}

- (UIButton *)setupLogoutButton {
    UIButton *logoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [logoutButton setTitle:@"Logout from This Account" forState:UIControlStateNormal];
    [logoutButton.titleLabel setFont:[UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold]];
    [logoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [logoutButton setTitleColor:[UIColor colorWithWhite:0.8 alpha:1.0] forState:UIControlStateHighlighted];

    UIImageSymbolConfiguration *iconConfig = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightMedium];
    UIImage *doorImage = [UIImage systemImageNamed:kLogoutIcon withConfiguration:iconConfig];
    [logoutButton setImage:doorImage forState:UIControlStateNormal];
    [logoutButton setTintColor:[UIColor whiteColor]];
    
    logoutButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10); // Space between icon and text
    logoutButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);

    logoutButton.frame = CGRectMake(20, 650, self.view.bounds.size.width - 40, 50);
    logoutButton.layer.cornerRadius = 25;
    logoutButton.clipsToBounds = YES;

    UIImage *gradientImage = [self imageFromLayer:({
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = logoutButton.bounds;
        gradient.cornerRadius = 25; 
        gradient.colors = @[
            (id)[UIColor colorWithRed:220/255.0 green:50/255.0 blue:50/255.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:180/255.0 green:30/255.0 blue:80/255.0 alpha:1.0].CGColor
        ];
        gradient.startPoint = CGPointMake(0.0, 0.5);
        gradient.endPoint = CGPointMake(1.0, 0.5);
        gradient;
    })];

    [logoutButton setBackgroundImage:gradientImage forState:UIControlStateNormal];
    logoutButton.layer.shadowColor = [UIColor colorWithRed:180/255.0 green:30/255.0 blue:80/255.0 alpha:1.0].CGColor;
    logoutButton.layer.shadowOffset = CGSizeMake(0, 4);
    logoutButton.layer.shadowRadius = 8;
    logoutButton.layer.shadowOpacity = 0.5;
    logoutButton.layer.masksToBounds = NO;

    [logoutButton addTarget:self action:@selector(handleLogout) forControlEvents:UIControlEventTouchUpInside];
    return logoutButton;
}

- (UIButton *)setupAccountButtonWithTitle:(NSString *)title selector:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold]];
    [button setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIImageView *)setupHeaderImage {
    UIImageView *headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(155, 120, 80, 80)];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:40.0 weight:UIImageSymbolWeightRegular];
    headerImageView.image = [UIImage systemImageNamed:kPersonIcon withConfiguration:config];
    headerImageView.tintColor = [UIColor whiteColor];
    headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
    headerImageView.layer.shadowColor = [UIColor blackColor].CGColor;
    headerImageView.layer.shadowOffset = CGSizeMake(0, 2);
    headerImageView.layer.shadowOpacity = 0.3;
    headerImageView.layer.shadowRadius = 4;
    return headerImageView;
}

- (UIView *)setupHeaderView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    CAGradientLayer *gradientLayer = [self setupGradientLayer];
    [headerView.layer insertSublayer:gradientLayer atIndex:0];
    UIView *noiseOverlay = [[UIView alloc] initWithFrame:headerView.bounds];
    noiseOverlay.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.05]; 
    noiseOverlay.layer.compositingFilter = kCompositionFilter; 
    [headerView addSubview:noiseOverlay];
    CAGradientLayer *highlightGradient = [CAGradientLayer layer];
    highlightGradient.frame = CGRectMake(0, 0, self.view.frame.size.width, 100);
    highlightGradient.colors = @[
        (id)[UIColor colorWithRed:50/255.0 green:70/255.0 blue:100/255.0 alpha:0.2].CGColor,
        (id)[UIColor colorWithRed:20/255.0 green:30/255.0 blue:50/255.0 alpha:0.0].CGColor
    ];
    highlightGradient.locations = @[@0.0, @1.0];
    [headerView.layer insertSublayer:highlightGradient atIndex:1];
    return headerView;
}

- (UIImage *)imageFromLayer:(CALayer *)layer {
    UIGraphicsBeginImageContextWithOptions(layer.bounds.size, NO, [UIScreen mainScreen].scale);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

-(UILabel *)createLabelWithText:(NSString *)text fontSize:(CGFloat)fontSize {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

- (void)updateCountry {
    NSString *searchCountry = [IPARUtils getKeyFromFile:kCountrySearchKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
    self.searchCountryLabel.text = [NSString stringWithFormat:@"Search In Appstore Country: %@ [%@]", [IPARUtils emojiFlagForISOCountryCode:searchCountry], searchCountry];
    NSString *downloadCountry = [IPARUtils getKeyFromFile:kCountryDownloadKeyFromFile defaultValueIfNil:kDefaultInitialCountry];
    self.downloadCountryLabel.text = [NSString stringWithFormat:@"Download From Appstore Country: %@ [%@]", [IPARUtils emojiFlagForISOCountryCode:downloadCountry], downloadCountry];
}

- (void)handleLogout {
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        NSString *accountId = [IPARUtils activeAccountId];
        NSString *commandToExecute = [NSString stringWithFormat:kLogoutCommand, kIpatoolScriptPath];
        NSDictionary *lastCommandResult = [IPARUtils executeCommandAndGetJSON:kLaunchPathBash arg1:kBashCommandKey arg2:commandToExecute arg3:nil accountId:accountId];
        if ([lastCommandResult[kJsonLevel] isEqualToString:kJsonLevelError]) {
            [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:lastCommandResult[kJsonLevelError] hasTextfield:NO withTextfieldBlock:nil
                        alertConfirmationBlock:nil withConfirmText:@"Continue anyway" alertCancelBlock:nil withCancelText:nil presentOn:self];
        }
        [IPARUtils deleteAccountWithId:accountId];
        if ([IPARUtils accounts].count > 0) {
            [self resetToTabs];
        } else {
            [self resetToLogin];
        }
    };
    [IPARUtils presentDialogWithTitle:kIPARangerLogouHeadline message:@"This will revoke the local token for this account and remove it from IPARanger." hasTextfield:NO withTextfieldBlock:nil
                            alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Yes" alertCancelBlock:nil withCancelText:@"No" presentOn:self];
}

- (void)handleAddAccount {
    [self resetToLogin];
}

- (void)handleSwitchAccount {
    NSArray *accounts = [IPARUtils accounts];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Switch Account" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSDictionary *account in accounts) {
        NSString *accountId = account[kAccountIdKey];
        NSString *title = account[kAccountEmailKeyFromFile] ?: account[kAccountLabelKey] ?: accountId;
        [alert addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [IPARUtils activateAccountWithId:accountId];
            [self resetToTabs];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 0, 0);
        alert.popoverPresentationController.permittedArrowDirections = 0;
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetToLogin {
    IPARLoginScreenViewController *loginScreenVC = [[IPARLoginScreenViewController alloc] init];
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self.tabBarController.view removeFromSuperview];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginScreenVC];
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    window.rootViewController = navController;
}

- (void)resetToTabs {
    IPARSearchViewController *searchVC = [[IPARSearchViewController alloc] init];
    UINavigationController *searchNC = [[UINavigationController alloc] initWithRootViewController:searchVC];

    IPARDownloadViewController *downloadVC = [[IPARDownloadViewController alloc] init];
    UINavigationController *downloadNC = [[UINavigationController alloc] initWithRootViewController:downloadVC];

    IPARAccountAndCredits *accountVC = [[IPARAccountAndCredits alloc] init];
    UINavigationController *accountNC = [[UINavigationController alloc] initWithRootViewController:accountVC];

    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[searchNC, downloadNC, accountNC];

    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    window.rootViewController = tabBarController;
}
@end
