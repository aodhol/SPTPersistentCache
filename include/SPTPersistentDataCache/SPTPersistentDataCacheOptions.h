#import <Foundation/Foundation.h>

@class SPTPersistentCacheResponse;

/**
 * Type off callback for load/store calls
 */
typedef void (^SPTDataCacheResponseCallback)(SPTPersistentCacheResponse *response);

/**
 * Type of callback that is used to give caller a chance to choose which key to open if any.
 */
typedef NSString *(^SPTDataCacheChooseKeyCallback)(NSArray *keys);

/**
 * Type of callback that is used to provide current time for that cache. Mainly for testing.
 */
typedef NSTimeInterval (^SPTDataCacheCurrentTimeSecCallback)(void);

/**
 * Type of callback that can be used ot get debug messages from cache.
 */
typedef void (^SPTDataCacheDebugCallback)(NSString *string);

/**
 * @brief SPTPersistentDataCacheOptions
 *
 * @discussion Class defines cache creation options
 */
@interface SPTPersistentDataCacheOptions : NSObject

/**
 * Path to a folder in which to store that files. If folder doesn't exist it will be created.
 * This mustn't be nil.
 */
@property (nonatomic, copy) NSString *cachePath;
/**
 * Garbage collection interval. It is guaranteed that once started GC runs with this interval.
 * Its recommended to use SPTPersistentDataCacheDefaultGCIntervalSec constant if not sure.
 * Internal guarding is applied to this value.
 */
@property (nonatomic, assign) NSUInteger gcIntervalSec;
/**
 * Default time which have to pass since last file access so file could be candidate for pruning on next GC.
 * Its recommended to use SPTPersistentDataCacheDefaultExpirationTimeSec if not sure.
 * Internal guarding is applied.
 */
@property (nonatomic, assign) NSUInteger defaultExpirationPeriodSec;
/**
 * Size in bytes to which cache should adjust itself when performing GC. 0 - no size constraint (default)
 */
@property (nonatomic, assign) NSUInteger sizeConstraintBytes;
/**
 * Callback used to supply debug/internal information usually about errors.
 */
@property (nonatomic, copy) SPTDataCacheDebugCallback debugOutput;
/**
 * Callback to provide current time in seconds. This time shouldn't depend on time zone etc.
 * So its better to use fixed time scale i.e. UNIX. If not specified then current unix time is used.
 */
@property (nonatomic, copy) SPTDataCacheCurrentTimeSecCallback currentTimeSec;
/**
 * Any string that identifies the cache and used in naming of internal queue.
 * It is important to put sane string to be able identify queue during debug and in crash dumps.
 * Default is "persistent.cache".
 */
@property (nonatomic, copy) NSString *cacheIdentifier;
/**
 * Use 2 first letter of key for folder names to separate recodrs into. Default: YES
 */
@property (nonatomic, assign) BOOL folderSeparationEnabled;

@end