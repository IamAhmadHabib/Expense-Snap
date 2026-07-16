enum SyncState {
  localOnly,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  synced,
  failed,
}

extension SyncStateChecks on SyncState {
  bool get needsSync {
    return this == SyncState.pendingCreate ||
        this == SyncState.pendingUpdate ||
        this == SyncState.pendingDelete ||
        this == SyncState.failed;
  }
}
