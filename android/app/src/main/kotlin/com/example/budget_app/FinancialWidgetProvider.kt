package com.example.budget_app

import android.appwidget.AppWidgetManager
import android.app.PendingIntent
import android.content.Intent
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class FinancialWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val availableBalance = widgetData.getString("availableBalance", "0")
                val dailyIncome = widgetData.getString("dailyIncome", "+0")
                val dailyExpense = widgetData.getString("dailyExpense", "-0")
                
                setTextViewText(R.id.tv_available_balance_value, availableBalance)
                setTextViewText(R.id.tv_daily_income_value, dailyIncome)
                setTextViewText(R.id.tv_daily_expense_value, dailyExpense)
                
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

