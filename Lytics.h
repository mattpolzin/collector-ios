
// Lytics.h
//
// Code based on Countly SDK source: https://github.com/Countly/countly-sdk-ios
//
// Modified by Mathew Polzin, Vadio Inc.
//
// This code is provided under the MIT License.
//
// Please visit www.count.ly for more information.

#define LYTICS_DEBUG 0

#if LYTICS_DEBUG
#   define LYTICS_LOGI(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#   define LYTICS_LOGI(...)
#endif

#define LYTICS_VERSION "1.01"

#import <Foundation/Foundation.h>

@class EventQueue;

@interface Lytics : NSObject {
	double unsentSessionLength;
	NSTimer *timer;
	double lastTime;
	BOOL isSuspended;
    EventQueue *eventQueue;
	
	time_t sessionStartTimestamp;
	
	NSString* uuid;
}

// The uuid (unique user id) gets sent to Lytics if it is set (by default it is
// created and set for you if the general setting generate_or_load_CFUUID is
// set to YES). You can also set the uuid yourself and that value will get
// sent to Lytics. If no value is set, Lytics will not receive any information
// that allows them to assosciate each incoming event with any other events.
@property (nonatomic, retain) NSString* uuid;

+ (Lytics *)sharedInstance;

// Start the Lytics session. The account ID and Lytics host URL are
// provided by Lytics.
- (void)start:(NSString *)accountID withHost:(NSString*)appHost;

// Use these to perform session tracking. Often it might be desirable to end
// the current session when the user puts your app in the background and start
// a new session when the user comes back to your app. Your app may be
// technically running in the background for an arbitrarily long time while the
// user does whatever else on the phone.
- (void)startSession;
- (void)endSession;

// Record event with given name and include only the fields defined in the
// special "all" category.
- (void)recordEvent:(NSString *)key;

// Record an event and include parameters from 1 or more categories (see
// LyticsSettings.plist).
- (void)recordEvent:(NSString *)key category:(NSString*)category;
- (void)recordEvent:(NSString *)key categories:(NSArray*)categories;

// Record event and include the key/value pairs in the given dictionary
// as additional parameters.
- (void)recordEvent:(NSString *)key parameters:(NSDictionary*)parameters;

// Record event in given categories with given additional parameters.
- (void)recordEvent:(NSString *)key category:(NSString*)category parameters:(NSDictionary*)parameters;
- (void)recordEvent:(NSString *)key categories:(NSArray*)categories parameters:(NSDictionary*)parameters;

// Get the session time for this Lytics object.
- (NSNumber*)sessionTime;

@end


