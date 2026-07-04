#import "IPARVersionPickerViewController.h"
#import "../Cells/IPARVersionCell.h"

@interface IPARVersionPickerViewController ()
@property (nonatomic, strong) NSArray *versions;
@property (nonatomic, copy) IPARVersionPickerCompletion completion;
@end

@implementation IPARVersionPickerViewController

- (instancetype)initWithVersions:(NSArray *)versions completion:(IPARVersionPickerCompletion)completion {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _versions = versions ?: @[];
        _completion = [completion copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Select Version";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped)];
    self.tableView.backgroundColor = UIColor.systemBackgroundColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[IPARVersionCell class] forCellReuseIdentifier:@"VersionCell"];
}

- (void)cancelTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.versions.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IPARVersionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VersionCell" forIndexPath:indexPath];
    if (indexPath.row == 0) {
        [cell configureWithVersion:@"Latest version" detail:@"Current App Store version"];
    } else {
        NSDictionary *version = self.versions[indexPath.row - 1];
        NSString *versionText = [NSString stringWithFormat:@"%@", version[@"bundle_version"] ?: @"Unknown version"];
        [cell configureWithVersion:versionText detail:[self detailTextForVersion:version]];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}

- (NSString *)detailTextForVersion:(NSDictionary *)version {
    NSMutableArray *parts = [NSMutableArray array];
    NSString *createdAt = [NSString stringWithFormat:@"%@", version[@"created_at"] ?: @""];
    if (createdAt.length >= 10) {
        [parts addObject:[createdAt substringToIndex:10]];
    }
    NSString *externalID = [NSString stringWithFormat:@"%@", version[@"external_identifier"] ?: @""];
    if (externalID.length > 0) {
        [parts addObject:[NSString stringWithFormat:@"ID %@", externalID]];
    }
    return [parts componentsJoinedByString:@" · "];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *externalVersionID = @"";
    if (indexPath.row > 0) {
        NSDictionary *version = self.versions[indexPath.row - 1];
        externalVersionID = [NSString stringWithFormat:@"%@", version[@"external_identifier"] ?: @""];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.completion) {
            self.completion(externalVersionID);
        }
    }];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"%lu versions available", (unsigned long)self.versions.count];
}

@end
