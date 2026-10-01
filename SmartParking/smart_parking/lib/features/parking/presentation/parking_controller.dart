import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/entities/parking_slot.dart';
import '../domain/entities/parking_details.dart';
import '../domain/repository/parking_repository.dart';

class ParkingNotice {
  final String message;
  final DateTime time;
  const ParkingNotice(this.message, this.time);
}

class ParkingController extends ChangeNotifier {
  final ParkingRepository repository;
  StreamSubscription<List<ParkingSlot>>? _subscription;
  Timer? _timer;
  Timer? _watchTimeout;
  bool _disposed = false;
  bool _refreshing = false;
  int _ticks = 0;
  int _generation = 0;
  final Set<String> _noticeKeys = {};
  final Map<String, SlotStatus> _previousStatuses = {};
  List<ParkingSlot> slots = [];
  MyParking mine = const MyParking();
  final List<ParkingNotice> notices = [];
  bool loading = true;
  bool busy = false;
  String? error;
  String? personalError;
  DateTime now = DateTime.now().toUtc();

  ParkingController(this.repository) {
    watch();
    refreshPersonal();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      now = DateTime.now().toUtc();
      _evaluate();
      if (++_ticks % 5 == 0) refreshPersonal();
      _notify();
    });
  }

  Future<void> watch() async {
    final generation = ++_generation;
    await _subscription?.cancel();
    if (_disposed || generation != _generation) return;
    loading = true;
    error = null;
    _notify();
    _watchTimeout?.cancel();
    _watchTimeout = Timer(const Duration(seconds: 15), () {
      if (!_disposed && generation == _generation && loading) {
        loading = false;
        error = 'Chưa nhận được dữ liệu bãi xe. Kiểm tra kết nối và thử lại.';
        _notify();
      }
    });
    _subscription = repository.watchParkingSlots().listen(
      (value) {
        if (_disposed || generation != _generation) return;
        slots = value;
        _watchTimeout?.cancel();
        loading = false;
        error = null;
        now = DateTime.now().toUtc();
        _evaluate();
        _notify();
      },
      onError: (Object e) {
        if (_disposed || generation != _generation) return;
        loading = false;
        error =
            'Không đọc được trạng thái bãi xe. Kiểm tra kết nối và thử lại.';
        _notify();
      },
    );
  }

  Future<void> refreshPersonal() async {
    if (_refreshing || _disposed) return;
    _refreshing = true;
    try {
      final value = await repository.getMyParking();
      if (!_disposed) {
        mine = value;
        personalError = null;
        _evaluate();
        _notify();
      }
    } catch (_) {
      if (!_disposed) {
        personalError = 'Chưa tải được lượt đặt và vị trí xe. Nhấn tải lại.';
        _notify();
      }
    } finally {
      _refreshing = false;
    }
  }

  ParkingBooking? get activeBooking {
    for (final booking in mine.bookings) {
      if (booking.activeAt(now)) return booking;
    }
    return null;
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) throw StateError('Đang xử lý thao tác trước.');
    busy = true;
    _notify();
    try {
      await action();
      await refreshPersonal();
    } finally {
      busy = false;
      _notify();
    }
  }

  void _addNotice(String key, String text) {
    if (_noticeKeys.add(key)) {
      notices.insert(0, ParkingNotice(text, now));
      if (notices.length > 50) notices.removeLast();
    }
  }

  void _evaluate() {
    if (error == null && !loading) {
      for (final slot in slots) {
        final status = slot.statusAt(now);
        final previous = _previousStatuses[slot.code];
        if (previous != null &&
            previous != SlotStatus.free &&
            status == SlotStatus.free) {
          _addNotice(
            'free:${slot.code}:${slot.lastSeenAt}:${slot.reservedUntil}',
            'Ô ${slot.code} đang trống và có thể đặt.',
          );
        }
        _previousStatuses[slot.code] = status;
      }
      final full =
          slots.isNotEmpty &&
          slots.every((s) {
            final status = s.statusAt(now);
            return status == SlotStatus.occupied ||
                status == SlotStatus.reserved;
          });
      if (full) {
        _addNotice('full', 'Bãi xe hiện hết chỗ khả dụng.');
      } else {
        _noticeKeys.remove('full');
      }
    }
    for (final booking in mine.bookings) {
      final seconds = booking.expiresAt.difference(now).inSeconds;
      if (booking.status == 'active' && seconds > 0 && seconds <= 120) {
        _addNotice(
          'warning:${booking.id}',
          'Chỗ đặt ${booking.code} sắp hết thời gian giữ.',
        );
      } else if (booking.status == 'active' && seconds <= 0) {
        _addNotice(
          'expired:${booking.id}',
          'Chỗ đặt ${booking.code} đã hết hạn.',
        );
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _subscription?.cancel();
    _timer?.cancel();
    _watchTimeout?.cancel();
    super.dispose();
  }
}
