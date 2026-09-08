package de.codesphere.speedster

import androidx.car.app.connection.CarConnection
import androidx.lifecycle.LiveData
import androidx.lifecycle.Observer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private var connectionType: LiveData<Int>? = null
    private var observer: Observer<Int>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "de.codesphere.speedster/car_connection",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                // Liefert den Verbindungsstatus zu Android Auto, ohne dass
                // die App selbst eine Auto-App sein muss.
                val liveData = CarConnection(this@MainActivity).type
                val o = Observer<Int> { type ->
                    events?.success(type != CarConnection.CONNECTION_TYPE_NOT_CONNECTED)
                }
                connectionType = liveData
                observer = o
                liveData.observe(this@MainActivity, o)
            }

            override fun onCancel(arguments: Any?) {
                observer?.let { connectionType?.removeObserver(it) }
                observer = null
                connectionType = null
            }
        })
    }
}
