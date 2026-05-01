package com.ollie.life_os

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Paint
import android.widget.RemoteViews
import org.json.JSONArray

class ChecklistWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("checklist_items", "[]") ?: "[]"
        val arr = try { JSONArray(json) } catch (e: Exception) { JSONArray() }

        val itemViews = listOf(
            R.id.checklist_item_1,
            R.id.checklist_item_2,
            R.id.checklist_item_3,
            R.id.checklist_item_4,
            R.id.checklist_item_5,
        )

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.checklist_widget_layout)
            for (i in itemViews.indices) {
                if (i < arr.length()) {
                    val item = arr.getJSONObject(i)
                    val title = item.optString("title", "")
                    val done = item.optBoolean("done", false)
                    val prefix = if (done) "✓ " else "○ "
                    views.setTextViewText(itemViews[i], "$prefix$title")
                    views.setInt(itemViews[i], "setAlpha", if (done) 80 else 220)
                } else {
                    views.setTextViewText(itemViews[i], "")
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
