using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace LocalNotify
{
    public static class Notify
    {
        static bool _registered = false;

        extern(Android)
        static Notify()
        {
            AndroidImpl.Init();
        }

        extern(iOS)
        static Notify()
        {
            if (!_registered)
            {
                LocalNotify.iOSImpl.ReceivedLocalNotification += OnReceived;
                _registered = true;
            }
        }

        //----------------------------------------------------------------------

        public static void Now(string title, string body, string payload, bool sound=true, int badgeNumber=0)
        {
            Later(0, title, body, payload, sound, badgeNumber);
        }

        //----------------------------------------------------------------------

        public static extern(android) void Later(int secondsFromNow, string title, string body, string payload, bool sound=true,
                                                 int badgeNumber=0)
        {
            AndroidImpl.Later(title, body, sound, payload, secondsFromNow);
        }

        public static extern(iOS) void Later(int secondsFromNow, string title, string body, string payload, bool sound=true,
                                             int badgeNumber=0)
        {
            iOSImpl.Later(title, body, sound, payload, secondsFromNow, badgeNumber);
        }

        public static extern(!MOBILE) void Later(int secondsFromNow, string title, string body, string payload, bool sound=true,
                                                 int badgeNumber=0)
        {
            debug_log "Sorry LocalNotify is not supported on this backend";
        }

        //----------------------------------------------------------------------

        static List<KeyValuePair<string,bool>> _pendingNotifications = new List<KeyValuePair<string,bool>>();

        static event EventHandler<KeyValuePair<string,bool>> _receivedNotification;

        public static event EventHandler<KeyValuePair<string,bool>> Received
        {
            add
            {
                _receivedNotification += value;
                foreach (var n in _pendingNotifications)
                    value(null, n);
                _pendingNotifications.Clear();
            }
            remove {
                _receivedNotification -= value;
            }
        }

        internal static void OnReceived(object sender, KeyValuePair<string,bool> notification)
        {
            var x = _receivedNotification;
            if (x!=null){
                x(null, notification);
            }
            else
                _pendingNotifications.Add(notification);
        }

        //----------------------------------------------------------------------

        [Foreign(Language.ObjC)]
        public extern(iOS) static void ClearBadgeNumber()
        @{
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        @}

        public extern(!iOS) static void ClearBadgeNumber() { }

        [Foreign(Language.ObjC)]
        public extern(iOS) static void ClearAllNotifications()
        @{
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
        @}

        [Foreign(Language.Java)]
        public extern(Android) static void ClearAllNotifications()
        @{
            android.app.Activity activity = com.fuse.Activity.getRootActivity();
            android.app.NotificationManager nMgr = (android.app.NotificationManager)activity.getSystemService(android.content.Context.NOTIFICATION_SERVICE);
            nMgr.cancelAll();
        @}

        public extern(!iOS && !Android) static void ClearAllNotifications() { }

        //------------------------------------------------------------

        [Foreign(Language.ObjC)]
        public extern(iOS) static void CancelPendingNotifications()
        @{
	    NSArray *arrayOfLocalNotifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
	    for (UILocalNotification* localNotification in arrayOfLocalNotifications) {
		[[UIApplication sharedApplication] cancelLocalNotification:localNotification] ;
	    }
        @}

        [Foreign(Language.Java)]
        public extern(Android) static void CancelPendingNotifications()
        @{
	    android.app.Activity activity = com.fuse.Activity.getRootActivity();
	    android.content.Intent intent =
        	new android.content.Intent(activity, com.fusedCompound.LocalNotify.LocalNotificationReceiver.class);
	    debug_log("should cancel all pending");
	    com.fusedCompound.LocalNotify.AlarmUtils.cancelAllAlarms(activity, intent);
        @}

        public extern(!iOS && !Android) static void CancelPendingNotifications() { }
    }
}
