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
            Later(0, title, body, payload, sound, badgeNumber, null);
        }

        //----------------------------------------------------------------------

        public static extern(android) void Later(int secondsFromNow, string title,
                                                 string body, string payload, bool sound=true,
                                                 int badgeNumber=0,
                                                 Fuse.Scripting.Object channelInfo)
        {
            string channelId = null;
            if (channelInfo != null)
            {
                channelId = (string)channelInfo["id"];
                if (channelId == null) throw new Exception("channel id is mandatory if channelInfo is specified");
                var name = (string)channelInfo["channelName"];
                var description = (string)channelInfo["description"];
                var importanceStr = (string)channelInfo["importance"];
                // https://developer.android.com/reference/android/support/v4/app/NotificationManagerCompat.html#IMPORTANCE_DEFAULT
                int importance = -1000;
                if (importanceStr == "IMPORTANCE_DEFAULT") importance = 3;
                else if (importanceStr == "IMPORTANCE_HIGH") importance = 4;
                else if (importanceStr == "IMPORTANCE_LOW") importance = 2;
                else if (importanceStr == "IMPORTANCE_MAX") importance = 5;
                else if (importanceStr == "IMPORTANCE_MIN") importance = 1;
                else if (importanceStr == "IMPORTANCE_NONE") importance = 0;
                else if (importanceStr == "IMPORTANCE_UNSPECIFIED")  importance =-1000;
                else importance = 3;

                AndroidImpl.CreateNotificationChannel(channelId, name, importance, description);
            }
            AndroidImpl.Later(title, body, sound, payload, channelId, secondsFromNow);
        }

        public static extern(iOS) void Later(int secondsFromNow, string title, string body,
                                             string payload, bool sound=true,
                                             int badgeNumber=0,
                                             Fuse.Scripting.Object channelInfo = null)
        {
            iOSImpl.Later(title, body, sound, payload, secondsFromNow, badgeNumber);
        }

        public static extern(!MOBILE) void Later(int secondsFromNow, string title,
                                                 string body, string payload, bool sound=true,
                                                 int badgeNumber=0,
                                                 object channelInfo = null)
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
