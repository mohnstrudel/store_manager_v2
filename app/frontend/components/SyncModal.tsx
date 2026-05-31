import { router, Link } from "@inertiajs/react";
import { useCallback, type MouseEvent } from "react";

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
  const handleClose = useCallback(() => onClose(), [onClose]);
  const handleBackdropClick = useCallback(
    (event: MouseEvent<HTMLDialogElement>) => {
      if (event.target === event.currentTarget) onClose();
    },
    [onClose],
  );
  const pull = useCallback(
    (limit?: number) => {
      router.post(pullPath, limit ? { limit } : {});
      onClose();
    },
    [onClose, pullPath],
  );
  const pullAll = useCallback(() => pull(), [pull]);
  const pullLimited = useCallback(() => pull(100), [pull]);

  return (
    <dialog id={id} onClick={handleBackdropClick} open>
      <div className="dialog_content rounded-lg shadow-lg w-xl p-4 pb-6 -translate-y-10">
        <header className="nav_header mb-6 pb-4">
          <hgroup>
            <h2>{title}</h2>
            {lastSyncAt && <h4 className="font-medium">{lastSyncAt}</h4>}
          </hgroup>
          <button
            aria-label="Close"
            className="btn is-muted is-inverted small"
            onClick={handleClose}
            type="button"
          >
            ❌
          </button>
        </header>

        <menu className="flex flex-col gap-4">
          <li>
            <button className="w-full h-15 btn_blue btn_rounded" onClick={pullAll} type="button">
              {fetchAllLabel}
            </button>
          </li>
          <li>
            <button className="w-full h-15 btn_rounded" onClick={pullLimited} type="button">
              {fetchLimitedLabel}
            </button>
          </li>
          <li>
            <Link className="w-full h-15" href="/jobs/statuses" prefetch>
              Track Jobs Progress
            </Link>
          </li>
        </menu>
      </div>
    </dialog>
  );
}
