package com.sunilkhatri.aerostep

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import java.util.Locale

private fun steps(data: SharedPreferences) = data.getInt("steps", 0)
private fun goal(data: SharedPreferences) = data.getInt("goal", 10000).coerceAtLeast(1)
private fun fmt(n: Int): String = NumberFormat.getIntegerInstance().format(n)

/** 2x2 Sunset Tangerine steps widget. */
class AeroStepSmallWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val s = steps(widgetData)
            val g = goal(widgetData)
            val pct = (s * 100 / g)
            val views = RemoteViews(context.packageName, R.layout.aerostep_small_widget).apply {
                setTextViewText(R.id.widget_steps, fmt(s))
                setTextViewText(R.id.widget_goal, "/ ${fmt(g)} steps")
                setProgressBar(R.id.widget_progress, 100, pct.coerceIn(0, 100), false)
                setTextViewText(R.id.widget_percent, "${pct.coerceIn(0, 999)}%")
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/** 4x2 interactive Bento widget with a +250 ml water tap. */
class AeroStepBentoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val s = steps(widgetData)
            val g = goal(widgetData)
            val ml = widgetData.getInt("hydration_ml", 0)
            val views = RemoteViews(context.packageName, R.layout.aerostep_bento_widget).apply {
                setTextViewText(R.id.widget_steps, fmt(s))
                setTextViewText(R.id.widget_goal, "/ ${fmt(g)}")
                setProgressBar(R.id.widget_progress, 100, (s * 100 / g).coerceIn(0, 100), false)
                setTextViewText(R.id.widget_kcal, "${widgetData.getInt("kcal", 0)} kcal")
                setTextViewText(R.id.widget_cadence, "${widgetData.getInt("cadence", 0)} SPM")
                setTextViewText(R.id.widget_water, String.format(Locale.US, "%.2f / 2.5 L", ml / 1000.0))
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                setOnClickPendingIntent(
                    R.id.widget_water_button,
                    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("aerostep://water?ml=250")),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
