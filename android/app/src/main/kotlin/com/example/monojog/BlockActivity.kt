package com.example.monojog

import android.app.Activity
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.Drawable
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

class BlockActivity : Activity() {

    // ── Theme Colors ──
    private var bgColor = 0
    private var titleColor = 0
    private var subtitleColor = 0
    private var warningBg = 0
    private var warningBorder = 0
    private var warningText = 0
    private var warningIcon = 0
    private var buttonBg = 0
    private var buttonText = 0
    private var quoteColor = 0
    private var lockCircleBg = 0
    private var lockIconColor = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupThemeColors()

        val scrollView = ScrollView(this).apply {
            setBackgroundColor(bgColor)
            isFillViewport = true
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(28), dp(0), dp(28), dp(40))
        }

        // ══════════════════════════════════
        // 1. Lock Icon Circle (top center)
        // ══════════════════════════════════
        val lockContainer = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(120), dp(120)).apply {
                topMargin = dp(100)
                gravity = Gravity.CENTER_HORIZONTAL
            }
        }

        // Circle background
        val circleView = View(this).apply {
            layoutParams = FrameLayout.LayoutParams(dp(120), dp(120))
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(lockCircleBg)
            }
        }
        lockContainer.addView(circleView)

        // Lock icon (drawn via custom drawable — no XML)
        val lockView = View(this).apply {
            layoutParams = FrameLayout.LayoutParams(dp(52), dp(56)).apply {
                gravity = Gravity.CENTER
            }
            background = LockDrawable(lockIconColor)
        }
        lockContainer.addView(lockView)

        root.addView(lockContainer)

        // ══════════════════════════════════
        // 2. Title — "মনোযোগ মোড সক্রিয়"
        // ══════════════════════════════════
        val title = TextView(this).apply {
            text = "মনোযোগ মোড সক্রিয়"
            textSize = 28f
            setTextColor(titleColor)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dp(32)
            }
        }
        root.addView(title)

        // ══════════════════════════════════
        // 3. Subtitle
        // ══════════════════════════════════
        val subtitle = TextView(this).apply {
            text = "এই অ্যাপটি ব্লক করা আছে\nমনোযোগ দিয়ে পড়াশোনা করুন!"
            textSize = 16f
            setTextColor(subtitleColor)
            gravity = Gravity.CENTER
            setLineSpacing(dp(4).toFloat(), 1f)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dp(16)
            }
        }
        root.addView(subtitle)

        // ══════════════════════════════════
        // 4. Warning Banner (yellow box)
        // ══════════════════════════════════
        val warningLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(18), dp(16), dp(18), dp(16))
            background = GradientDrawable().apply {
                setColor(warningBg)
                cornerRadius = dp(16).toFloat()
                setStroke(dp(1), warningBorder)
            }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dp(36)
            }
        }

        // Warning icon "⚠"
        val warnIcon = TextView(this).apply {
            text = "⚠️"
            textSize = 20f
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                marginEnd = dp(12)
            }
        }
        warningLayout.addView(warnIcon)

        val warnText = TextView(this).apply {
            text = "মনোযোগ মোড শেষ না হওয়া পর্যন্ত\nঅপেক্ষা করুন"
            textSize = 14f
            setTextColor(warningText)
            typeface = Typeface.DEFAULT_BOLD
            setLineSpacing(dp(3).toFloat(), 1f)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        warningLayout.addView(warnText)

        root.addView(warningLayout)

        // ══════════════════════════════════
        // 5. "মনোযোগে ফিরে যান" Button
        // ══════════════════════════════════
        val primaryBtn = TextView(this).apply {
            text = "মনোযোগে ফিরে যান"
            textSize = 17f
            setTextColor(buttonText)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(dp(40), dp(16), dp(40), dp(16))
            background = GradientDrawable().apply {
                setColor(buttonBg)
                cornerRadius = dp(30).toFloat()
            }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dp(36)
                gravity = Gravity.CENTER_HORIZONTAL
            }
            isClickable = true
            isFocusable = true
            setOnClickListener { navigateToMainApp() }
        }
        root.addView(primaryBtn)

        // ══════════════════════════════════
        // 6. Bottom Quote
        // ══════════════════════════════════
        val quote = TextView(this).apply {
            text = "\"সফলতার জন্য মনোযোগ সবচেয়ে গুরুত্বপূর্ণ\""
            textSize = 13f
            setTextColor(quoteColor)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dp(40)
                gravity = Gravity.CENTER_HORIZONTAL
            }
        }
        root.addView(quote)

        scrollView.addView(root)
        setContentView(scrollView)
    }

    // ═══════════════════════════════════
    // THEME SETUP — Dark + Light mode
    // ═══════════════════════════════════

    private fun setupThemeColors() {
        val isDark = (resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

        if (isDark) {
            // ── DARK MODE ──
            bgColor         = Color.parseColor("#0D0D12")
            titleColor      = Color.parseColor("#FFFFFF")
            subtitleColor   = Color.parseColor("#9999AA")
            warningBg       = Color.parseColor("#2A2518")
            warningBorder   = Color.parseColor("#4D3F1A")
            warningText     = Color.parseColor("#F0C040")
            warningIcon     = Color.parseColor("#F0C040")
            buttonBg        = Color.parseColor("#6C63FF")
            buttonText      = Color.WHITE
            quoteColor      = Color.parseColor("#555566")
            lockCircleBg    = Color.parseColor("#3D3A6E")
            lockIconColor   = Color.WHITE
        } else {
            // ── LIGHT MODE ──
            bgColor         = Color.parseColor("#E8EAF0")
            titleColor      = Color.parseColor("#3A3680")
            subtitleColor   = Color.parseColor("#555577")
            warningBg       = Color.parseColor("#FFF5D6")
            warningBorder   = Color.parseColor("#F0E0A0")
            warningText     = Color.parseColor("#8B7020")
            warningIcon     = Color.parseColor("#E0A800")
            buttonBg        = Color.parseColor("#6C63FF")
            buttonText      = Color.WHITE
            quoteColor      = Color.parseColor("#8888AA")
            lockCircleBg    = Color.parseColor("#7B75D3")
            lockIconColor   = Color.WHITE
        }
    }

    // ═══════════════════════════════════════════════════
    // LOCK DRAWABLE — আসল তালার মতো (Pure Canvas)
    // ═══════════════════════════════════════════════════

    private class LockDrawable(private val color: Int) : Drawable() {

        private val bodyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = this@LockDrawable.color
            style = Paint.Style.FILL
        }

        private val shacklePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = this@LockDrawable.color
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }

        private val keyholePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
        }

        override fun draw(canvas: Canvas) {
            val w = bounds.width().toFloat()
            val h = bounds.height().toFloat()
            val cx = w / 2f

            // ── Shackle (U-আকৃতি) ──────────────────────────
            // দুটো সোজা পা উপরে উঠে গিয়ে অর্ধবৃত্তে মিলেছে
            val shackleStroke = w * 0.14f
            shacklePaint.strokeWidth = shackleStroke

            // শ্যাকেলের বাম ও ডান পায়ের X পজিশন
            val shackleLeft  = cx - w * 0.21f
            val shackleRight = cx + w * 0.21f

            // বডির উপরের দিক — শ্যাকেলের পা এখানে ঢোকে
            val bodyTop      = h * 0.44f
            // শ্যাকেলের পা বডির ভেতরে একটু ঢোকানো (overlap)
            val legBottom    = bodyTop + shackleStroke * 0.6f

            // অর্ধবৃত্তের ব্যাসার্ধ (শ্যাকেলের প্রস্থের অর্ধেক)
            val arcRadius    = (shackleRight - shackleLeft) / 2f
            // অর্ধবৃত্তের কেন্দ্র Y
            val arcCenterY   = h * 0.08f + arcRadius

            val shacklePath = Path().apply {
                // বাম পায়ের নিচ থেকে শুরু করে উপরে যাই
                moveTo(shackleLeft, legBottom)
                lineTo(shackleLeft, arcCenterY)

                // উপরে অর্ধবৃত্ত (বাম থেকে ডানে)
                val arcRect = RectF(
                    shackleLeft,
                    arcCenterY - arcRadius,
                    shackleRight,
                    arcCenterY + arcRadius
                )
                arcTo(arcRect, 180f, 180f, false)

                // ডান পা নিচে নামে
                lineTo(shackleRight, legBottom)
            }
            canvas.drawPath(shacklePath, shacklePaint)

            // ── Lock Body (চ্যাপ্টা গোলাকার বাক্স) ────────
            // আসল তালার মতো body টা একটু চওড়া ও ছোট উচ্চতার
            val bodyRect = RectF(
                w * 0.06f,
                bodyTop,
                w * 0.94f,
                h * 0.97f
            )
            val bodyRadius = w * 0.14f
            canvas.drawRoundRect(bodyRect, bodyRadius, bodyRadius, bodyPaint)

            // ── Keyhole (বৃত্ত + নিচে আয়তক্ষেত্র) ──────────
            keyholePaint.color = if (color == Color.WHITE)
                Color.parseColor("#6C63FF")
            else
                Color.parseColor("#E8EAF0")

            val bodyMidY   = bodyTop + (h * 0.97f - bodyTop) * 0.5f
            val kcy        = bodyTop + (h * 0.97f - bodyTop) * 0.33f  // বৃত্তের কেন্দ্র (উপরের দিকে)
            val kRadius    = w * 0.095f

            // কীহোল বৃত্ত
            canvas.drawCircle(cx, kcy, kRadius, keyholePaint)

            // কীহোল নিচের আয়তাকার ছিদ্র (বৃত্ত থেকে নিচে নামে)
            val slotW  = kRadius * 0.75f
            val slotTop    = kcy + kRadius * 0.5f
            val slotBottom = kcy + kRadius * 2.2f
            val slotRect = RectF(
                cx - slotW,
                slotTop,
                cx + slotW,
                slotBottom
            )
            canvas.drawRoundRect(slotRect, slotW * 0.4f, slotW * 0.4f, keyholePaint)
        }

        override fun setAlpha(alpha: Int) {
            bodyPaint.alpha = alpha
            shacklePaint.alpha = alpha
            keyholePaint.alpha = alpha
        }

        override fun setColorFilter(cf: ColorFilter?) {
            bodyPaint.colorFilter = cf
            shacklePaint.colorFilter = cf
            keyholePaint.colorFilter = cf
        }

        @Deprecated("Deprecated in Java")
        override fun getOpacity(): Int = PixelFormat.TRANSLUCENT
    }

    // ═══════════════════════════════════
    // NAVIGATION
    // ═══════════════════════════════════

    private fun navigateToMainApp() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        if (intent != null) {
            startActivity(intent)
        }
        finish()
    }

    private fun goHome() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        goHome()
    }

    // ═══════════════════════════════════
    // DP HELPER
    // ═══════════════════════════════════

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()
    }
}