package com.example.budget_app

import android.appwidget.AppWidgetManager
import android.app.PendingIntent
import android.content.Intent
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class MonthlyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout_monthly).apply {
                val monthlySpent = widgetData.getString("monthlySpent", "0")
                val budgetLeft = widgetData.getString("budgetLeft", "0")
                val budgetLeftLabel = widgetData.getString("budgetLeftLabel", "left")
                val budgetProgress = widgetData.getInt("budgetProgress", 0)
                
                setTextViewText(R.id.tv_monthly_spent, monthlySpent)
                setTextViewText(R.id.tv_budget_left, budgetLeft)
                setTextViewText(R.id.tv_budget_label, " $budgetLeftLabel")
                setProgressBar(R.id.progress_bar, 100, budgetProgress, false)
                
                if (budgetLeftLabel == "over") {
                    setTextColor(R.id.tv_budget_left, android.graphics.Color.parseColor("#F44336"))
                } else {
                    setTextColor(R.id.tv_budget_left, android.graphics.Color.parseColor("#4CAF50"))
                }
                
                // Add click listener to launch app
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

