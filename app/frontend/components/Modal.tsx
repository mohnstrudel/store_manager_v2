import { XMarkIcon } from "@heroicons/react/20/solid";
import {
  useCallback,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type MouseEvent,
  type ReactNode,
  type SyntheticEvent,
} from "react";

type ModalProps = {
  children: ReactNode;
  id?: string;
  isBusy?: boolean;
  onClose: () => void;
  subtitle?: string | null;
  title: string;
};

export default function Modal({
  children,
  id,
  isBusy = false,
  onClose,
  subtitle,
  title,
}: ModalProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const titleId = useId();
  const [isShown, setIsShown] = useState(false);

  useLayoutEffect(() => {
    const dialog = dialogRef.current;
    dialog?.showModal();
    // oxlint-disable-next-line react/set-state-in-effect -- children must mount after showModal so their autoFocus lands inside the open dialog
    setIsShown(true);

    return () => dialog?.close();
  }, []);

  const requestClose = useCallback(() => {
    if (!isBusy) onClose();
  }, [isBusy, onClose]);

  const handleCancel = useCallback(
    (event: SyntheticEvent<HTMLDialogElement>) => {
      event.preventDefault();
      requestClose();
    },
    [requestClose],
  );

  const handleBackdropClick = useCallback(
    (event: MouseEvent<HTMLDialogElement>) => {
      if (event.target === event.currentTarget) requestClose();
    },
    [requestClose],
  );

  return (
    // oxlint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-noninteractive-element-interactions -- backdrop click; Escape arrives as the native cancel event
    <dialog
      ref={dialogRef}
      aria-labelledby={titleId}
      id={id}
      onCancel={handleCancel}
      onClick={handleBackdropClick}
    >
      <div className="dialog_content">
        <header className="mb-6 flex items-center justify-between gap-4">
          <hgroup>
            <h2 id={titleId}>{title}</h2>
            {subtitle ? <p className="mt-1 text-gray-500 dark:text-gray-400">{subtitle}</p> : null}
          </hgroup>
          <button
            aria-label="Close"
            className="dialog_close btn_rounded"
            disabled={isBusy}
            onClick={requestClose}
            type="button"
          >
            <XMarkIcon height={20} width={20} />
          </button>
        </header>
        {isShown ? children : null}
      </div>
    </dialog>
  );
}
