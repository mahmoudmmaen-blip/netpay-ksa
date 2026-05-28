import 'eosb_wizard_screen.dart';

/// مسار `/eosb` — حاسبة نهاية الخدمة (معالج EOSB المستقل).
class EosbScreen extends EosbWizardScreen {
  const EosbScreen({super.key}) : super(dedicatedEosbBranding: true);
}
