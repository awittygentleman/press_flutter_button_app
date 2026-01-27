package com.example.press_me_app

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.press_me_app/audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "muteAudio" -> {
                    muteDevice()
                    result.success(null)
                }
                "unmuteAudio" -> {
                    unmuteDevice()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun muteDevice() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0)
        audioManager.setStreamVolume(AudioManager.STREAM_NOTIFICATION, 0, 0)
        audioManager.setStreamVolume(AudioManager.STREAM_RING, 0, 0)
    }

    private fun unmuteDevice() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, maxVolume / 2, 0)
        audioManager.setStreamVolume(AudioManager.STREAM_NOTIFICATION, maxVolume / 2, 0)
        audioManager.setStreamVolume(AudioManager.STREAM_RING, maxVolume / 2, 0)
    }
}