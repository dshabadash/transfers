

#import "MTLModel.h"
#import "MTLJSONAdapter.h"


@interface LSITunesSoftwareItem : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSString *kind;
@property (nonatomic, strong, readonly) NSArray *features;
@property (nonatomic, strong, readonly) NSArray *supportedDevices;
@property (nonatomic, strong, readonly) NSArray *advisories;
@property (nonatomic, strong, readonly) NSString *isGameCenterEnabled;
@property (nonatomic, strong, readonly) NSArray *screenshotUrls;
@property (nonatomic, strong, readonly) NSArray *ipadScreenshotUrls;
@property (nonatomic, strong, readonly) NSString *artworkUrl60;
@property (nonatomic, strong, readonly) NSString *artworkUrl100;
@property (nonatomic, strong, readonly) NSString *artworkUrl512;
@property (nonatomic, strong, readonly) NSString *artistViewUrl;
@property (nonatomic, strong, readonly) NSString *artistId;
@property (nonatomic, strong, readonly) NSString *artistName;
@property (nonatomic, strong, readonly) NSString *price;
@property (nonatomic, strong, readonly) NSString *version;
@property (nonatomic, strong, readonly) NSString *itemDescription;
@property (nonatomic, strong, readonly) NSString *currency;
@property (nonatomic, strong, readonly) NSArray *genres;
@property (nonatomic, strong, readonly) NSArray *genreIds;
@property (nonatomic, strong, readonly) NSString *releaseDate;
@property (nonatomic, strong, readonly) NSString *sellerName;
@property (nonatomic, strong, readonly) NSString *bundleId;
@property (nonatomic, strong, readonly) NSString *trackId;
@property (nonatomic, strong, readonly) NSString *trackName;
@property (nonatomic, strong, readonly) NSString *primaryGenreName;
@property (nonatomic, strong, readonly) NSString *primaryGenreId;
@property (nonatomic, strong, readonly) NSString *releaseNotes;
@property (nonatomic, strong, readonly) NSString *minimumOsVersion;
@property (nonatomic, strong, readonly) NSString *wrapperType;
@property (nonatomic, strong, readonly) NSString *formattedPrice;
@property (nonatomic, strong, readonly) NSString *trackCensoredName;
@property (nonatomic, strong, readonly) NSArray *languageCodesISO2A;
@property (nonatomic, strong, readonly) NSString *fileSizeBytes;
@property (nonatomic, strong, readonly) NSString *sellerUrl;
@property (nonatomic, strong, readonly) NSString *contentAdvisoryRating;
@property (nonatomic, strong, readonly) NSString *averageUserRatingForCurrentVersion;
@property (nonatomic, strong, readonly) NSString *userRatingCountForCurrentVersion;
@property (nonatomic, strong, readonly) NSString *trackViewUrl;
@property (nonatomic, strong, readonly) NSString *trackContentRating;
@property (nonatomic, strong, readonly) NSString *averageUserRating;
@property (nonatomic, strong, readonly) NSString *userRatingCount;

@end
