package com.sirolf2009.samurai

import com.sirolf2009.samurai.annotations.Register
import com.sirolf2009.samurai.dataprovider.DataProviderBitcoinCharts
import com.sirolf2009.samurai.gui.NumberField
import com.sirolf2009.samurai.gui.NumberSpinner
import com.sirolf2009.samurai.gui.TabPaneBacktest
import com.sirolf2009.samurai.gui.TimeframePicker
import com.sirolf2009.samurai.gui.TreeItemDataProvider
import com.sirolf2009.samurai.gui.TreeItemStrategy
import com.sirolf2009.samurai.strategy.IStrategy
import com.sirolf2009.samurai.strategy.Param
import java.io.File
import javafx.beans.property.ReadOnlyObjectProperty
import javafx.geometry.Insets
import javafx.scene.control.Button
import javafx.scene.control.Label
import javafx.scene.control.Separator
import javafx.scene.control.Tab
import javafx.scene.control.TabPane
import javafx.scene.control.TitledPane
import javafx.scene.control.TreeItem
import javafx.scene.control.TreeView
import javafx.scene.image.Image
import javafx.scene.image.ImageView
import javafx.scene.layout.Background
import javafx.scene.layout.BackgroundFill
import javafx.scene.layout.BackgroundImage
import javafx.scene.layout.BackgroundPosition
import javafx.scene.layout.BackgroundRepeat
import javafx.scene.layout.BackgroundSize
import javafx.scene.layout.BorderPane
import javafx.scene.layout.CornerRadii
import javafx.scene.layout.GridPane
import javafx.scene.layout.VBox
import javafx.scene.paint.Color
import org.reflections.Reflections
import org.reflections.scanners.SubTypesScanner
import org.reflections.scanners.TypeAnnotationsScanner

import static extension com.sirolf2009.samurai.util.GUIUtil.*

class SamuraiBacktest extends BorderPane {

	val backtests = new TabPane()

	var TreeItemDataProvider provider
	var IStrategy strategy

	new(Samurai samurai) {
		center = backtests
		val image = new BackgroundImage(new Image(Samurai.getResourceAsStream("/icon.png"), 157, 157, true, true), BackgroundRepeat.NO_REPEAT, BackgroundRepeat.NO_REPEAT, BackgroundPosition.CENTER, BackgroundSize.DEFAULT)
		backtests.background = new Background(#[new BackgroundFill(Color.BLACK.brighter, new CornerRadii(0), new Insets(0))], #[image])

		val dataPane = new TitledPane("Data", null)
		val strategyPane = new TitledPane("Strategy", null)
		val parametersPane = new TitledPane("Parameters", null)
		val parametersGrid = new GridPane() => [
			padding = new Insets(4)
		]
		val timeframePicker = new TimeframePicker() => [
			satisfiedProperty.addListener [ observable, old, newValue |
				if(newValue) {
					parametersPane.graphic = new ImageView(new Image(Samurai.getResourceAsStream("/ok.png")))
				} else {
					parametersPane.graphic = null
				}
			]
		]
		val runBacktest = new Button("Run Backtest") => [
			disableProperty -> dataPane.graphicProperty.isNull().or(strategyPane.graphicProperty.isNull())
			maxWidth = Double.MAX_VALUE
			onMouseClicked = [
				strategy.class.fields.filter [
					annotations.findFirst[it.annotationType == Param] != null
				].forEach [ it, index |
					val value = {
						val field = parametersGrid.getNodeByRowColumnIndex(index, 1)
						if(field instanceof NumberField) {
							(field as NumberField).number
						} else if(field instanceof NumberSpinner) {
							(field as NumberSpinner).number
						} else {
							null
						}
					}
					if(type == Integer || type == Integer.TYPE) {
						set(strategy, value.intValue)
					} else {
						set(strategy, value)
					}
				]
				val provider = provider.provider.get() => [
					period = timeframePicker.period
					from = timeframePicker.from
					to = timeframePicker.to
				]
				backtests.tabs += new Tab(strategy.class.simpleName, new TabPaneBacktest(samurai, provider, strategy))
			]
		]

		left = new VBox(
			dataPane => [
				content = new TreeView => [
					root = new TreeItem("") => [
						children += new TreeItem("BitcoinCharts") => [
							children += new TreeItemDataProvider("BTCCNY - OkCoin", [new DataProviderBitcoinCharts(new File("data/okcoinCNY.csv"))])
							children += new TreeItemDataProvider("BTCUSD - OkCoin", [new DataProviderBitcoinCharts(new File("data/bitfinexUSD.csv"))])
							children += new TreeItemDataProvider("BTCUSD - Bitstamp", [new DataProviderBitcoinCharts(new File("data/bitstampUSD.csv"))])
						]
					]
					showRoot = false
					selectionModel.selectedItemProperty.addListener [
						val item = (it as ReadOnlyObjectProperty<TreeItem<String>>).value
						if(item instanceof TreeItemDataProvider) {
							provider = item as TreeItemDataProvider
							dataPane.graphic = new ImageView(new Image(Samurai.getResourceAsStream("/ok.png")))
							dataPane.expanded = false
							strategyPane.expanded = true
							parametersPane.expanded = false
						}
					]
					expandAllNodes
				]
			],
			strategyPane => [
				expanded = false
				content = new TreeView => [
					root = new TreeItem("Strategy") => [
						children += new TreeItem("Built-In") => [
							val reflections = new Reflections("", new SubTypesScanner(), new TypeAnnotationsScanner())
							reflections.getTypesAnnotatedWith(Register).filter[interfaces.findFirst[IStrategy.isAssignableFrom(it)] != null].forEach [ strategyClass |
								val name = (strategyClass.annotations.findFirst[annotationType == Register] as Register).name
								val strategy = strategyClass.newInstance() as IStrategy
								children += new TreeItemStrategy(name, strategy)
							]
						]
					]
					showRoot = false
					selectionModel.selectedItemProperty.addListener [
						val item = (it as ReadOnlyObjectProperty<TreeItem<String>>).value
						if(item instanceof TreeItemStrategy) {
							strategy = item.strategy
							strategyPane.graphic = new ImageView(new Image(Samurai.getResourceAsStream("/ok.png")))
							dataPane.expanded = false
							strategyPane.expanded = false
							parametersPane.expanded = true

							strategy.class.fields.filter [
								annotations.findFirst[it.annotationType == Param] != null
							].forEach [ field, index |
								parametersGrid.add(new Label(field.name), 0, index)
								if(field.type == Integer || field.type == Integer.TYPE) {
									parametersGrid.add(new NumberSpinner(field.get(strategy) as Integer, 1), 1, index)
								}
							]
						}
					]
					expandAllNodes
				]
			],
			parametersPane => [
				expanded = false
				content = new VBox => [
					children += parametersGrid
					children += new Separator()
					children += timeframePicker
				]
			],
			runBacktest
		)
	}

}