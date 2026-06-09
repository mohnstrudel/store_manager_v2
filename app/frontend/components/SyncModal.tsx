import { router, Link } from "@inertiajs/react";
import { useCallback, type MouseEvent } from "react";
import { useCloseOnEscape } from "@/utils/useCloseOnEscape";

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
  const { closeModal, closeWhenBackdropIsClicked } = useSyncModalDismissal(onClose);
  const { fetchEverything, fetchRecentRecords } = useStoreSyncActions({
    onClose,
    pullPath,
  });

  return (
    <dialog id={id} onClick={closeWhenBackdropIsClicked} open>
      <div className="dialog_content rounded-lg shadow-lg w-xl p-4 pb-6 -translate-y-10">
        <SyncModalHeader lastSyncAt={lastSyncAt} onClose={closeModal} title={title} />

        <SyncActions
          fetchAllLabel={fetchAllLabel}
          fetchLimitedLabel={fetchLimitedLabel}
          onFetchAll={fetchEverything}
          onFetchLimited={fetchRecentRecords}
        />
      </div>
    </dialog>
  );
}

type SyncModalHeaderProps = {
  lastSyncAt?: string | null;
  onClose: () => void;
  title: string;
};

function SyncModalHeader({ lastSyncAt, onClose, title }: SyncModalHeaderProps) {
  return (
    <header className="nav_header mb-6 pb-4">
      <hgroup>
        <h2>{title}</h2>
        {lastSyncAt && <h4 className="font-medium">{lastSyncAt}</h4>}
      </hgroup>
      <button
        aria-label="Close"
        className="btn is-muted is-inverted small"
        onClick={onClose}
        type="button"
      >
        <i className="icn">❌</i>
      </button>
    </header>
  );
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
        <button className="w-full h-15 btn_blue btn_rounded" onClick={onFetchAll} type="button">
          {fetchAllLabel}
        </button>
      </li>
      <li>
        <button className="w-full h-15 btn_rounded" onClick={onFetchLimited} type="button">
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

function useSyncModalDismissal(onClose: () => void) {
  useCloseOnEscape(true, onClose);

  const closeModal = useCallback(() => onClose(), [onClose]);

  const closeWhenBackdropIsClicked = useCallback(
    (event: MouseEvent<HTMLDialogElement>) => {
      if (event.target === event.currentTarget) onClose();
    },
    [onClose],
  );

  return { closeModal, closeWhenBackdropIsClicked };
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
