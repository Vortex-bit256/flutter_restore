void ShowAfterFirstFrame() {
  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });
}
