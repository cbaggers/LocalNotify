package com.fusedCompound.LocalNotify;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class LocalNotificationReceiver extends BroadcastReceiver {
    public static boolean InForeground = false;

    @Override
    public void onReceive(Context context, Intent intent)
    {
        com.foreign.LocalNotify.AndroidImpl.OnNotificationRecieved(context, intent);
    }
}
