package com.sirolf2009.samurai.renderer.chart

import com.sirolf2009.samurai.renderer.RendererDefault
import eu.verdelhan.ta4j.TimeSeries
import eu.verdelhan.ta4j.TradingRecord
import javafx.scene.canvas.Canvas
import javafx.scene.paint.Color

class ChartPrice extends Chart {
	
	static val renderer = new RendererDefault()
	
	val TimeSeries series
	val TradingRecord tradingRecord
	val ChartData data
	
	new(Canvas canvas, TimeSeries series, TradingRecord tradingRecord, ChartData data) {
		super(canvas)
		this.series = series
		this.tradingRecord = tradingRecord
		this.data = data
	}
	
	override draw() {
		if(series != null) {
			val g = canvas.graphicsContext2D
			g.save()
			g.fill = Color.BLACK.brighter
			g.fillRect(0, 0, canvas.width, canvas.height)

			renderer.drawChart(data, canvas, g, scrollX, zoomX)

			g.restore()
		}
	}
	
}