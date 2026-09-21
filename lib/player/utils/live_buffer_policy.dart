/// Bounded low-latency buffer budget for non-seekable live streams.
///
/// A 64 MiB forward budget covers roughly sixteen seconds at 32 Mbit/s,
/// while providing adequate jitter absorption for live CDN streams.
/// The 8 MiB back budget protects short decoder/output transitions.
abstract final class LiveBufferPolicy {
  static const int forwardBytes = 64 * 1024 * 1024;
  static const int backBytes = 8 * 1024 * 1024;
  static const int readaheadSeconds = 5;
}
