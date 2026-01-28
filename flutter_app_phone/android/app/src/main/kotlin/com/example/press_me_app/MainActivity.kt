package com.example.press_me_app

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.press_me_app/audio"
    private var savedMusicVolume = 0
    private var savedNotificationVolume = 0
    private var savedRingVolume = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "muteAudio" -> {
                    try {
                        muteDevice()
                        result.success("Device muted")
                    } catch (e: Exception) {
                        result.error("MUTE_ERROR", e.message, null)
                    }
                }
                "unmuteAudio" -> {
                    try {
                        unmuteDevice()
                        result.success("Device unmuted")
                    } catch (e: Exception) {
                        result.error("UNMUTE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun muteDevice() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        // Save current volumes BEFORE muting
        savedMusicVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        savedNotificationVolume = audioManager.getStreamVolume(AudioManager.STREAM_NOTIFICATION)
        savedRingVolume = audioManager.getStreamVolume(AudioManager.STREAM_RING)
        
        println("MUTE - Saved volumes: Music=$savedMusicVolume, Notification=$savedNotificationVolume, Ring=$savedRingVolume")
        
        // Mute all streams (NO DND changes)
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0)
        audioManager.setStreamVolume(AudioManager.STREAM_NOTIFICATION, 0, 0)
        audioManager.setStreamVolume(AudioManager.STREAM_RING, 0, 0)
    }

    private fun unmuteDevice() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        println("UNMUTE - Restoring volumes: Music=$savedMusicVolume, Notification=$savedNotificationVolume, Ring=$savedRingVolume")
        
        // Restore volumes
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, savedMusicVolume, 0)
        audioManager.setStreamVolume(AudioManager.STREAM_NOTIFICATION, savedNotificationVolume, 0)
        audioManager.setStreamVolume(AudioManager.STREAM_RING, savedRingVolume, 0)
    }
}