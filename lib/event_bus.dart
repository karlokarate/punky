import 'package:event_bus/event_bus.dart';
import 'core/event_bus.dart';

/// Global shortcut for the app-wide [EventBus].
final EventBus eventBus = AppEventBus.I.bus;
