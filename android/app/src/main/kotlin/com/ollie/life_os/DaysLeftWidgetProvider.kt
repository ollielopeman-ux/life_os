package com.ollie.life_os

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import java.util.Calendar

class DaysLeftWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val now = Calendar.getInstance()
        val year = now.get(Calendar.YEAR)
        val yearEnd = Calendar.getInstance().apply { set(year + 1, 0, 1, 0, 0, 0) }
        val daysLeft = ((yearEnd.timeInMillis - now.timeInMillis) / 86_400_000).toInt()
        val yearStart = Calendar.getInstance().apply { set(year, 0, 1, 0, 0, 0) }
        val totalDays = ((yearEnd.timeInMillis - yearStart.timeInMillis) / 86_400_000).toInt()
        val elapsed = totalDays - daysLeft
        val progress = (elapsed.toFloat() / totalDays * 100).toInt().coerceIn(0, 100)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.days_left_widget_layout)
            views.setTextViewText(R.id.days_left_year, year.toString())
            views.setTextViewText(R.id.days_left_count, daysLeft.toString())
            views.setProgressBar(R.id.days_left_progress, 100, progress, false)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
