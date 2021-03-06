#include <Uno/Uno.h>
#include "AppDelegateLocalNotify.h"
@{Fuse.Platform.Lifecycle:IncludeDirective}
@{LocalNotify.iOSImpl:IncludeDirective}

@implementation uContext (LocalNotify)

- (void)initializeLocalNotifications:(UIApplication *)application  {
	[application registerUserNotificationSettings:
	 [UIUserNotificationSettings settingsForTypes:
	  UIUserNotificationTypeAlert|
	  UIUserNotificationTypeBadge|
	  UIUserNotificationTypeSound
	  categories:nil]];
	@{LocalNotify.iOSImpl.SendPendingFromLaunchOptions():Call()};
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	uAutoReleasePool pool;
	NSError* err = NULL;
	NSMutableDictionary* userInfo;

	if (notification.userInfo)
		userInfo = [notification.userInfo mutableCopy];
	else
		userInfo = [NSMutableDictionary dictionary];

	if (notification.alertAction)
		[userInfo setObject:notification.alertAction forKey:@"title"];
	if (notification.alertBody)
		[userInfo setObject:notification.alertBody forKey:@"body"];

	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:&err];
	if (jsonData)
	{
		NSString* nsJsonPayload = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		@{Uno.String} jsonPayload = uPlatform::iOS::ToUno(nsJsonPayload);
		bool fromNotifBar = application.applicationState != UIApplicationStateActive;
		@{LocalNotify.iOSImpl.OnReceivedLocalNotification(string, bool):Call(jsonPayload, fromNotifBar)};
	}
}

@end
