#import <UIKit/UIKit.h>

typedef void (^IPARVersionPickerCompletion)(NSString *externalVersionID);

@interface IPARVersionPickerViewController : UITableViewController
- (instancetype)initWithVersions:(NSArray *)versions completion:(IPARVersionPickerCompletion)completion;
@end
