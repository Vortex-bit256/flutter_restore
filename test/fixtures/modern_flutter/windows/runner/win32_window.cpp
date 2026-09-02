void SetDarkTitleBar() {
  DwmSetWindowAttribute(nullptr, DWMWA_USE_IMMERSIVE_DARK_MODE, nullptr, 0);
}
