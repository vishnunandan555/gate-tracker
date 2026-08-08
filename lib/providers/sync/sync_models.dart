enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  requiresAction, // When both local and cloud data exist on first sign-in
  paused, // When retries cap after no network connection
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final Map<String, dynamic>? pendingCloudData; // Saved during initial conflict

  SyncState({
    required this.status,
    this.lastSyncedAt,
    this.errorMessage,
    this.pendingCloudData,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    Map<String, dynamic>? pendingCloudData,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingCloudData: pendingCloudData ?? this.pendingCloudData,
    );
  }
}
