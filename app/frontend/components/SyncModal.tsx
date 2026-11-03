import { router, Link } from "@inertiajs/react";
import { useCallback } from "react";

import Modal from "./Modal";

type SyncModalProps = {
  id: string;
  lastSyncAt?: string | null;
  fetchAllLabel?: string;
  fetchLimitedLabel: string;
  onClose: () => void;
  pullPath: string;
  title: string;
};

const LIMITED_SYNC_COUNT = 100;

export default function SyncModal({
  id,
  lastSyncAt,
  fetchAllLabel = "Fetch Everything",
  fetchLimitedLabel,
  onClose,
  pullPath,
  title,
}: SyncModalProps) {
  const { fetchEverything, fetchRecentRecords } = useStoreSyncActions({
    onClose,
    pullPath,
  });

  return (
    <Modal id={id} onClose={onClose} subtitle={lastSyncAt} title={title}>
      <SyncActions
        fetchAllLabel={fetchAllLabel}
        fetchLimitedLabel={fetchLimitedLabel}
        onFetchAll={fetchEverything}
        onFetchLimited={fetchRecentRecords}
      />
    </Modal>
  );
}

type StoreSyncActionsOptions = {
  onClose: () => void;
  pullPath: string;
};

function useStoreSyncActions({ onClose, pullPath }: StoreSyncActionsOptions) {
  const fetchStoreRecords = useCallback(
    (limit?: number) => {
      router.post(pullPath, limit ? { limit } : {});
      onClose();
    },
    [onClose, pullPath],
  );

  const fetchEverything = useCallback(() => fetchStoreRecords(), [fetchStoreRecords]);
  const fetchRecentRecords = useCallback(
    () => fetchStoreRecords(LIMITED_SYNC_COUNT),
    [fetchStoreRecords],
  );

  return { fetchEverything, fetchRecentRecords };
}

type SyncActionsProps = {
  fetchAllLabel: string;
  fetchLimitedLabel: string;
  onFetchAll: () => void;
  onFetchLimited: () => void;
};

function SyncActions({
  fetchAllLabel,
  fetchLimitedLabel,
  onFetchAll,
  onFetchLimited,
}: SyncActionsProps) {
  return (
    <menu className="flex flex-col gap-4">
      <li>
        <button className="w-full h-15 btn_blue" onClick={onFetchAll} type="button">
          {fetchAllLabel}
        </button>
      </li>
      <li>
        <button className="w-full h-15" onClick={onFetchLimited} type="button">
          {fetchLimitedLabel}
        </button>
      </li>
      <li>
        <Link className="w-full h-15" href="/jobs/statuses" prefetch>
          Track Jobs Progress
        </Link>
      </li>
    </menu>
  );
}
