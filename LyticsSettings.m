//
//  LyticsSettings.m
//
//  Created by Mathew Polzin on 10/17/12.
//

#import "LyticsSettings.h"

// If STATIC_LINKING is true, then instead of trying to load settings from the
// LyticsSettings.plist file, the settings are hardcoded into a dictionary so
// they can be maintained through static linking into a library. Of course, if
// you want to create a static library, the alternative to using the
// STATIC_LINKING flag is to include the LyticsSettings.plist file in the
// parent project that links with your static library and it will get loaded
// just fine.
#define STATIC_LINKING 0

static LyticsSettings* _lyticsSettings = nil;

@interface LyticsSettings (PrivateMethods)

// Convenience method; passes method call on to settings dictionary.
- (id)objectForKey:(NSString*)key;

// Convenience method; passes method call on to shared LyticsSettings object.
+ (id)objectForKey:(NSString*)key;

#if STATIC_LINKING
- (NSDictionary*)generateStaticSettings;
#endif

@end

@implementation LyticsSettings (PrivateMethods)

- (id)objectForKey:(NSString*)key
{
	return [self.settings objectForKey:key];
}

+ (id)objectForKey:(NSString*)key
{
	[LyticsSettings loadSettings];
	return [_lyticsSettings objectForKey:key];
}

#if STATIC_LINKING
// The following is NOT gauranteed to be up to date. Please use
// LyticsSettings.plist if you don't need to statically link a library. If you
// ARE creating a library, use LyticsSettings.plist to create a new literal
// representation of the settings for this method. The following tool will make
// it easy:
// https://github.com/H2CO3/Plist2ObjC
// OR my fork (identical)
// https://github.com/bumboarder6/Plist2ObjC
- (NSDictionary*)generateStaticSettings
{
	return	@{
				@"events": @{
					@"keys": @{
						@"LOAD_KEY": @"Load",
						@"SESSION_START_KEY": @"SessionStart",
						@"SESSION_UPDATE_KEY": @"SessionOpen",
						@"SESSION_END_KEY": @"SessionEnded"
					},
					@"default_tracked_events": @[
						@"LOAD_KEY",
						@"SESSION_START_KEY",
						@"SESSION_UPDATE_KEY",
						@"SESSION_END_KEY"
					]
				},
				@"general_settings": @{
					@"start_session_on_load": @"YES",
					@"generate_or_load_CFUUID": @"YES",
					@"end_session_on_app_focus_lost": @"NO"
				},
				@"parameters": @{
					@"global_keys": @{
						@"OS_KEY": @"os",
						@"CARRIER_KEY": @"carrier",
						@"TIMESTAMP_KEY": @"timestamp",
						@"CFUUID_KEY": @"uuid",
						@"LOCALE_KEY": @"locale",
						@"DEVICE_KEY": @"device",
						@"RESOLUTION_KEY": @"screen_resolution",
						@"APP_VERSION_KEY": @"app_version",
						@"OS_VERSION_KEY": @"os_version",
						@"SESSION_TIME_KEY": @"session_time"
					},
					@"categories": @{
						@"all": @[
							@"TIMESTAMP_KEY",
							@"SESSION_TIME_KEY",
							@"OS_KEY"
						],
						@"load": @[
							@"LOCALE_KEY",
							@"APP_VERSION_KEY"
						]
					},
					@"local_keys": @{
						@"EVENT_COUNT_KEY": @"count",
						@"EVENT_NAME_KEY": @"event"
					}
				}
			};
}
#endif

@end

@implementation LyticsSettings

@synthesize settings,globalParameterGetters;

- (id)init
{
	self = [super init];
	
	if (self) {
		NSString* fpath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"LyticsSettings.plist"];
#if STATIC_LINKING
		settings = [[self generateStaticSettings] retain];
#else
		settings = [[NSDictionary alloc] initWithContentsOfFile:fpath];
#endif
		
		globalParameterGetters = [[NSMutableDictionary alloc] initWithCapacity:[[settings objectForKey:@"global_keys"] count]];
	}
	
	return self;
}

+ (void)loadSettings
{
	if (_lyticsSettings == nil) {
		_lyticsSettings = [[LyticsSettings alloc] init];
	}
}

+ (id)generalSetting:(NSString*)settingName
{
	return [[LyticsSettings objectForKey:@"general_settings"] objectForKey:settingName];
}

+ (NSDictionary*)globalKeys
{
	return [[LyticsSettings objectForKey:@"parameters"] objectForKey:@"global_keys"];
}

+ (NSDictionary*)localKeys
{
	return [[LyticsSettings objectForKey:@"parameters"] objectForKey:@"local_keys"];
}

+ (NSDictionary*)categories
{
	return [[LyticsSettings objectForKey:@"parameters"] objectForKey:@"categories"];
}

+ (NSArray*)keysInCategory:(NSString *)category
{
	return [[LyticsSettings categories] objectForKey:category];
}

+ (NSString*)parameterNameForKey:(NSString*)key
{
	NSString* parameterName = [[LyticsSettings globalKeys] objectForKey:key];
	if (!parameterName) {
		parameterName = [[LyticsSettings localKeys] objectForKey:key];
		
		if (!parameterName) {
			parameterName = key;
		}
	}
	return parameterName;
}

+ (void)setAccessorForGlobalKey:(NSString*)key target:(id)target selector:(SEL)getter
{
	[LyticsSettings loadSettings];
	
	NSMethodSignature* m = [target methodSignatureForSelector:getter];
	NSInvocation* i = [NSInvocation invocationWithMethodSignature:m];
	[i setSelector:getter];
	[i setTarget:target];
	[_lyticsSettings.globalParameterGetters setObject:i forKey:key];
}

+ (id)getParameterValueForGlobalKey:(NSString*)key
{
	[LyticsSettings loadSettings];
	
	NSInvocation* i = [_lyticsSettings.globalParameterGetters objectForKey:key];
	if (i == nil) {
		[NSException raise:@"InvalidKeyException" format:@"The global parameter key %@ does not have an accessor assosciated with it (via setAccessorForGlobalKey:target:selector:).", key];
	}
	return [i.target performSelector:i.selector];
}

+ (NSArray*)defaultEventKeys
{
	return [[LyticsSettings objectForKey:@"events"] objectForKey:@"default_tracked_events"];
}

+ (NSString*)eventNameForKey:(NSString*)key
{
	NSString* eventName = [[[LyticsSettings objectForKey:@"events"] objectForKey:@"keys"] objectForKey:key];
	if (!eventName) {
		eventName = key;
	}
	return eventName;
}

- (void) dealloc
{
	[globalParameterGetters release], globalParameterGetters = nil;
	[settings release], settings = nil;
	[super dealloc];
}

@end
