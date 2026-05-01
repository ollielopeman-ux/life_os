package com.ollie.life_os

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.app.PendingIntent
import android.widget.RemoteViews

class GymWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val name = prefs.getString("gym_workout_name", "No workout today") ?: "No workout today"
        val exercises = prefs.getString("gym_exercises", "") ?: ""

        val tapIntent = Intent(Intent.ACTION_VIEW, Uri.parse("lifeos://gym/start"), context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, tapIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.gym_widget_layout)
            views.setTextViewText(R.id.gym_workout_name, name)
            views.setTextViewText(R.id.gym_exercises, exercises)
            views.setOnClickPendingIntent(R.id.gym_workout_name, pendingIntent)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
