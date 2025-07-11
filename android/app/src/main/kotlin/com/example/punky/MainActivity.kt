package com.example.punky

import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.ViewGroup
import android.view.animation.AnimationUtils
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.core.content.res.ResourcesCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterEngineConfigurator
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity(), FlutterEngineConfigurator {

    private var flutterReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        setSplashRandomBackground()
        super.onCreate(savedInstanceState)
        animatePunkyThenStartFlutter()
    }

    private fun setSplashRandomBackground() {
        val drawables = listOf(
            R.drawable.launch_background01,
            R.drawable.launch_background02,
            R.drawable.launch_background03,
            R.drawable.launch_background04,
            R.drawable.launch_background05,
            R.drawable.launch_background06,
        )
        val chosen = drawables.random()
        val bg = window.decorView.background
        if (bg is android.graphics.drawable.LayerDrawable) {
            bg.setDrawableByLayerId(
                android.R.id.background,
                ResourcesCompat.getDrawable(resources, chosen, theme)!!
            )
        }
    }

    private fun animatePunkyThenStartFlutter() {
        val imageView = ImageView(this).apply {
            setImageResource(R.drawable.icon)
            layoutParams = FrameLayout.LayoutParams(300, 300).apply {
                gravity = Gravity.CENTER
            }
        }

        val decor = window.decorView as ViewGroup
        decor.addView(imageView)

        val anim = AnimationUtils.loadAnimation(this, R.anim.punky_pop)
        imageView.startAnimation(anim)

        Handler(Looper.getMainLooper()).postDelayed({
            decor.removeView(imageView)
            if (!flutterReady) {
                flutterReady = true
                provideFlutterEngine(this)
                flutterEngine?.let { onFlutterUiDisplayed() }
            }
        }, 1200)
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        val engine = FlutterEngine(context)
        FlutterEngineCache.getInstance().put("main", engine)
        return engine
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {}
    override fun getRenderMode(): RenderMode = RenderMode.texture
    override fun getTransparencyMode(): TransparencyMode = TransparencyMode.transparent
}
