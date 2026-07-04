#import "IPARVersionCell.h"

static UIColor *IPARCardBackgroundColor(void) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithWhite:0.14 alpha:1.0];
        }
        return UIColor.secondarySystemBackgroundColor;
    }];
}

@implementation IPARVersionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.baseView = [[UIView alloc] init];
        self.baseView.backgroundColor = IPARCardBackgroundColor();
        self.baseView.clipsToBounds = YES;
        self.baseView.layer.cornerRadius = 12;
        self.baseView.layer.cornerCurve = kCACornerCurveContinuous;
        [self.contentView addSubview:self.baseView];
        [self.baseView top:self.contentView.topAnchor padding:7];
        [self.baseView leading:self.contentView.leadingAnchor padding:20];
        [self.baseView trailing:self.contentView.trailingAnchor padding:-20];
        [self.baseView bottom:self.contentView.bottomAnchor padding:-5];

        self.versionLabel = [[UILabel alloc] init];
        self.versionLabel.textColor = UIColor.labelColor;
        self.versionLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightSemibold];
        self.versionLabel.textAlignment = NSTextAlignmentLeft;
        self.versionLabel.adjustsFontSizeToFitWidth = YES;
        self.versionLabel.minimumScaleFactor = 0.55;
        [self.baseView addSubview:self.versionLabel];
        [self.versionLabel top:self.baseView.topAnchor padding:10];
        [self.versionLabel leading:self.baseView.leadingAnchor padding:14];
        [self.versionLabel trailing:self.baseView.trailingAnchor padding:-32];

        self.detailLabel = [[UILabel alloc] init];
        self.detailLabel.textColor = UIColor.tertiaryLabelColor;
        self.detailLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        self.detailLabel.textAlignment = NSTextAlignmentLeft;
        self.detailLabel.adjustsFontSizeToFitWidth = YES;
        self.detailLabel.minimumScaleFactor = 0.55;
        [self.baseView addSubview:self.detailLabel];
        [self.detailLabel top:self.versionLabel.bottomAnchor padding:2];
        [self.detailLabel leading:self.versionLabel.leadingAnchor padding:0];
        [self.detailLabel trailing:self.versionLabel.trailingAnchor padding:0];
        [self.detailLabel bottom:self.baseView.bottomAnchor padding:-10];

        UIImageView *chevron = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
        chevron.tintColor = UIColor.tertiaryLabelColor;
        chevron.contentMode = UIViewContentModeScaleAspectFit;
        [self.baseView addSubview:chevron];
        [chevron size:CGSizeMake(12, 18)];
        [chevron y:self.baseView.centerYAnchor padding:0];
        [chevron trailing:self.baseView.trailingAnchor padding:-14];
    }
    return self;
}

- (void)configureWithVersion:(NSString *)version detail:(NSString *)detail {
    self.versionLabel.text = version;
    self.detailLabel.text = detail;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.versionLabel.text = nil;
    self.detailLabel.text = nil;
}

@end
