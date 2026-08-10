import 'package:home_widget/home_widget.dart';
import '../../shared/models/radio_model.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.hepsiradyo.app';
  static const String androidWidgetName = 'HepsiRadyoWidget';

  static Future<void> updateWidgetData(RadioModel radio, {bool isPlaying = true}) async {
    try {
      await HomeWidget.saveWidgetData<String>('radio_name', radio.name);
      await HomeWidget.saveWidgetData<String>('radio_city', radio.city ?? 'Canlı');
      await HomeWidget.saveWidgetData<bool>('is_playing', isPlaying);
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: 'HepsiRadyoWidget',
      );
    } catch (_) {}
  }
}
