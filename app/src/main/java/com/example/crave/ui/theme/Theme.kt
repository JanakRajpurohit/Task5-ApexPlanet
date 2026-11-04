package com.example.crave.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val CraveColors = lightColorScheme(
    primary = Coral,
    onPrimary = Color.White,
    primaryContainer = PaleCoral,
    onPrimaryContainer = Ink,
    secondary = DarkTeal,
    onSecondary = Color.White,
    background = Cream,
    onBackground = Ink,
    surface = Color.White,
    onSurface = Ink,
    surfaceVariant = Color(0xFFF2ECE6),
    onSurfaceVariant = Muted,
    outline = Border,
    error = Color(0xFFB3261E)
)

@Composable
fun CraveTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = CraveColors,
        typography = CraveTypography,
        content = content
    )
}
