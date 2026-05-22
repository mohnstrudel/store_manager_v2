import { router, Link } from "@inertiajs/react";

type SyncModalProps = {
  id: string;
  lastSyncAt?: string | null;
  fetchAllLabel?: string;
  fetchLimitedLabel: string;
  onClose: () => void;
  pullPath: string;
  title: string;
};

export default function SyncModal({
  id,
  lastSyncAt,
  fetchAllLabel = "Fetch Everything",
  fetchLimitedLabel,
  onClose,
  pullPath,
  title,
}: SyncModalProps) {
  function pull(limit?: number) {
    router.post(pullPath, limit ? { limit } : {});
    onClose();
  }

  return (
    <dialog
      id={id}
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
      open
    >
      <div className="dialog-content rounded-lg shadow-lg w-xl p-4 pb-6 -translate-y-10">
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
            ❌
          </button>
        </header>

        <menu className="flex flex-col gap-4">
          <li>
            <button
              className="w-full h-15 btn-blue btn-rounded"
              onClick={() => pull()}
              type="button"
            >
              {fetchAllLabel}
            </button>
          </li>
          <li>
            <button className="w-full h-15 btn-rounded" onClick={() => pull(100)} type="button">
              {fetchLimitedLabel}
            </button>
          </li>
          <li>
            <Link className="w-full h-15" href="/jobs/statuses">
              Track Jobs Progress
            </Link>
          </li>
        </menu>
      </div>
    </dialog>
  );
}
