import { router } from "@inertiajs/react";
import { useCallback } from "react";

import Modal from "./Modal";

type SyncModalProps = {
  id: string;
  lastSyncAt?: string | null;
  onClose: () => void;
  pullPath: string;
  title: string;
};

type PullParams = { scope?: "changes" };

export default function SyncModal({ id, lastSyncAt, onClose, pullPath, title }: SyncModalProps) {
  const { fetchChanges, fetchEverything } = useStoreSyncActions({
    onClose,
    pullPath,
  });

  return (
    <Modal id={id} onClose={onClose} subtitle={lastSyncAt} title={title}>
      <SyncActions onFetchChanges={fetchChanges} onFetchEverything={fetchEverything} />
    </Modal>
  );
}

type StoreSyncActionsOptions = {
  onClose: () => void;
  pullPath: string;
};

function useStoreSyncActions({ onClose, pullPath }: StoreSyncActionsOptions) {
  const fetchStoreRecords = useCallback(
    (params: PullParams) => {
      router.post(pullPath, params);
      onClose();
    },
    [onClose, pullPath],
  );

  const fetchEverything = useCallback(() => fetchStoreRecords({}), [fetchStoreRecords]);
  const fetchChanges = useCallback(
    () => fetchStoreRecords({ scope: "changes" }),
    [fetchStoreRecords],
  );

  return { fetchChanges, fetchEverything };
}

type SyncActionsProps = {
  onFetchChanges: () => void;
  onFetchEverything: () => void;
};

function SyncActions({ onFetchChanges, onFetchEverything }: SyncActionsProps) {
  return (
    <menu className="flex flex-col gap-4">
      <li>
        <button className="w-full h-15 btn_blue" onClick={onFetchEverything} type="button">
          Fetch Everything
        </button>
      </li>
      <li>
        <button className="w-full h-15" onClick={onFetchChanges} type="button">
          Fetch Changes
        </button>
      </li>
      <li>
        <a className="w-full h-15" href="/jobs/statuses" rel="noopener noreferrer" target="_blank">
          Track Jobs Progress
        </a>
      </li>
    </menu>
  );
}
