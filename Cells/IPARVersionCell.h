#import "../Extensions/IPARConstraintExtension.h"

@interface IPARVersionCell : UITableViewCell
@property (nonatomic, retain) UIView *baseView;
@property (nonatomic, retain) UILabel *versionLabel;
@property (nonatomic, retain) UILabel *detailLabel;
- (void)configureWithVersion:(NSString *)version detail:(NSString *)detail;
@end
