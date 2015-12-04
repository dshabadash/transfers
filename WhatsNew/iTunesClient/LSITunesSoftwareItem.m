

#import "LSITunesSoftwareItem.h"
#import "ISO8601DateFormatter.h"


@interface LSITunesSoftwareItem()

@end

@implementation LSITunesSoftwareItem

/*
+ (ISO8601DateFormatter *)dateFormatter
{
    ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
    return formatter;
}
*/

#pragma mark - JSON Serialization

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{

    return @{ @"kind" : @"kind",
              @"features" : @"features",
              @"supportedDevices" : @"supportedDevices",
              @"advisories" : @"advisories",
              @"isGameCenterEnabled" : @"isGameCenterEnabled",
              @"screenshotUrls" : @"screenshotUrls",
              @"ipadScreenshotUrls" : @"ipadScreenshotUrls",
              @"artworkUrl60" : @"artworkUrl60",
              @"artworkUrl100" : @"artworkUrl100",
              @"artworkUrl512" : @"artworkUrl512",
              @"artistViewUrl" : @"artistViewUrl",
              @"artistId" : @"artistId",
              @"artistName" : @"artistName",
              @"price" : @"price",
              @"version" : @"version",
              @"itemDescription" : @"description",
              @"currency" : @"currency",
              @"genres" : @"genres",
              @"genreIds" : @"genreIds",
              @"releaseDate" : @"releaseDate",
              @"sellerName" : @"sellerName",
              @"bundleId" : @"bundleId",
              @"trackId" : @"trackId",
              @"trackName" : @"trackName",
              @"primaryGenreName" : @"primaryGenreName",
              @"primaryGenreId" : @"primaryGenreId",
              @"releaseNotes" : @"releaseNotes",
              @"minimumOsVersion" : @"minimumOsVersion",
               @"wrapperType" : @"wrapperType",
               @"formattedPrice" : @"formattedPrice",
               @"trackCensoredName" : @"trackCensoredName",
               @"languageCodesISO2A" : @"languageCodesISO2A",
               @"fileSizeBytes" : @"fileSizeBytes",
               @"sellerUrl" : @"sellerUrl",
               @"contentAdvisoryRating" : @"contentAdvisoryRating",
               @"averageUserRatingForCurrentVersion" : @"averageUserRatingForCurrentVersion",
               @"userRatingCountForCurrentVersion" : @"userRatingCountForCurrentVersion",
               @"trackViewUrl" : @"trackViewUrl",
               @"trackContentRating" : @"trackContentRating",
               @"averageUserRating" : @"averageUserRating",
               @"userRatingCount" : @"userRatingCount",

              };

}


/*
+ (NSValueTransformer *)releaseDateValueTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return [[self dateFormatter] dateFromString:str];
    } reverseBlock:^(NSDate *date) {
        return [[self dateFormatter] stringFromDate:date];
    }];
}
*/

@end
