enum OnboardingPagePosition { page1, page2, page3 }

extension OnboardingPagePositionExtension on OnboardingPagePosition {
  String onboardingpageimage() {
    switch (this) {
      case OnboardingPagePosition.page1:
        return 'asset/images/anh1.png';
      case OnboardingPagePosition.page2:
        return 'asset/images/anh2.png';
      case OnboardingPagePosition.page3:
        return 'asset/images/anh3.png';
    }
  }

  String onboardingpagetitle() {
    switch (this) {
      case OnboardingPagePosition.page1:
        return 'Tạo & Đồng bộ hành trình';
      case OnboardingPagePosition.page2:
        return 'Chia sẻ vị trí thời gian thực';
      case OnboardingPagePosition.page3:
        return 'Lưu giữ & Chia sẻ trải nghiệm';
    }
  }

  String onboardingpagecontent() {
    switch (this) {
      case OnboardingPagePosition.page1:
        return 'Lên kế hoạch chuyến đi cùng bạn bè chỉ trong vài bước.';
      case OnboardingPagePosition.page2:
        return 'Theo dõi vị trí của nhau trong suốt chuyến đi.';
      case OnboardingPagePosition.page3:
        return 'Đăng bài, chia sẻ khoảnh khắc và quản lý chi phí minh bạch.';
    }
  }
}
