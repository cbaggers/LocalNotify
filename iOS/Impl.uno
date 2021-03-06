using Uno;
using Uno.Graphics;
using Uno.Platform;
using Uno.Collections;
using Fuse;
using Fuse.Controls;
using Fuse.Triggers;
using Fuse.Resources;
using Uno.Compiler.ExportTargetInterop;

namespace LocalNotify
{
    [Require("Entity", "LocalNotify.iOSImpl.OnReceivedLocalNotification(string, bool)")]
    [Require("Entity", "LocalNotify.iOSImpl.SendPendingFromLaunchOptions()")]
    [Require("Entity", "Uno.Platform.iOS.Application.LaunchOptions")]
    [Require("uContext.SourceFile.DidFinishLaunching", "[self initializeLocalNotifications:[notification object]];")]
    [Require("uContext.SourceFile.Declaration", "#include <iOS/AppDelegateLocalNotify.h>")]
    internal extern(iOS) static class iOSImpl
    {
        public static void SendPendingFromLaunchOptions()
        {
            LocalNotify.iOSImpl.SendPendingFromLaunchOptions(Uno.Platform.iOS.Application.LaunchOptions);
        }

        [Foreign(Language.ObjC)]
        static void SendPendingFromLaunchOptions(ObjC.Object lOpts)
        @{
            NSDictionary* launchOptions = (NSDictionary*)lOpts;
            UILocalNotification* notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
            if (notification)
            {
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
                    @{LocalNotify.iOSImpl.OnReceivedLocalNotification(string, bool):Call(nsJsonPayload, true)};
                }
            }
        @}

        [Foreign(Language.ObjC)]
        internal static void Later(string title, string body, bool sound, string strPayload,
                                   int delaySeconds=0, int badgeNumber=0)
        @{
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:delaySeconds];
            notification.alertAction = title;
            notification.alertBody = body;
            notification.timeZone = [NSTimeZone defaultTimeZone];
            if (sound)
                notification.soundName = UILocalNotificationDefaultSoundName;
            notification.applicationIconBadgeNumber = badgeNumber;
            notification.userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     strPayload, @"payload", nil];

            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        @}

        public static event EventHandler<KeyValuePair<string,bool>> ReceivedLocalNotification;
        static List<KeyValuePair<string,bool>> DelayedLocalNotifications = new List<KeyValuePair<string,bool>>();

        internal static void OnReceivedLocalNotification(string notification, bool fromNotifBar)
        {
            if (Uno.Platform.CoreApp.State == ApplicationState.Foreground ||
                Uno.Platform.CoreApp.State == ApplicationState.Interactive)
            {
                var handler = ReceivedLocalNotification;
                if (handler != null)
                    handler(null, new KeyValuePair<string,bool>(notification, fromNotifBar));
            }
            else
            {
                DelayedLocalNotifications.Add(new KeyValuePair<string,bool>(notification, fromNotifBar));
                Uno.Platform.CoreApp.EnteringForeground += DispatchDelayedLocalNotifications;
            }
        }
        private static void DispatchDelayedLocalNotifications(ApplicationState state)
        {
            var handler = ReceivedLocalNotification;
            if (handler != null)
                foreach (var n in DelayedLocalNotifications)
                    handler(null, n);
            DelayedLocalNotifications.Clear();
            Uno.Platform.CoreApp.EnteringForeground -= DispatchDelayedLocalNotifications;
        }
    }
}
