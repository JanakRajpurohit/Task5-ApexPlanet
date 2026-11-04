package com.example.crave.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

val CraveTypography = Typography().let { defaults ->
    defaults.copy(
        headlineLarge = defaults.headlineLarge.copy(fontWeight = FontWeight.Bold, letterSpacing = (-0.5).sp),
        headlineMedium = defaults.headlineMedium.copy(fontWeight = FontWeight.Bold, letterSpacing = (-0.3).sp),
        titleLarge = defaults.titleLarge.copy(fontWeight = FontWeight.Bold),
        titleMedium = defaults.titleMedium.copy(fontWeight = FontWeight.SemiBold),
        bodyLarge = defaults.bodyLarge.copy(lineHeight = 24.sp),
        bodyMedium = defaults.bodyMedium.copy(lineHeight = 21.sp)
    )
}
