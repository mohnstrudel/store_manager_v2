import { Link } from "@inertiajs/react";
import { useEffect, useState } from "react";
import { useFlash } from "@/lib/useFlash";
import type { FlashMessage } from "@/types/inertia";

const AUTO_DISMISS_DELAY = 5000;
const TOAST_EXIT_DURATION = 300;
const TOAST_ENTER_DELAY = 0;
const FLASH_KIND = {
  alert: {
    articleClassName:
      "flash_toast pointer-events-auto bg-red-100 text-red-700 dark:bg-red-800/60 dark:text-red-300",
    icon: "🚨",
  },
  notice: {
    articleClassName:
      "flash_toast pointer-events-auto bg-lime-100 text-lime-700 dark:bg-lime-800/70 dark:text-lime-300/90",
    icon: "🙏",
  },
};

export default function FlashMessages() {
  const flash = useFlash();
  const activeKind = getActiveFlashKind(flash);
  const activeFlash = getActiveFlash(flash);
  const activeToken = activeFlash && activeKind ? flashToken(activeKind, activeFlash) : "";
  const toast = useFlashToast(activeFlash, activeKind, activeToken);

  if (!toast) return null;

  return (
    <div aria-live="polite" className="flash_toast_region" id="flash-messages">
      <article
        className={[
          FLASH_KIND[toast.kind].articleClassName,
          toast.phase === "visible" ? "opacity-100 translate-y-0 scale-100" : "opacity-0 -translate-y-4 scale-95",
          "transition-[opacity,transform] duration-300 ease-out motion-reduce:transition-none",
        ].join(" ")}
        role="status"
      >
        <i aria-hidden="true" className="icn text-2xl lg:text-3xl">
          {FLASH_KIND[toast.kind].icon}
        </i>
        <FlashMessageContent flash={toast.flash} />
        <i aria-hidden="true" className="icn text-2xl lg:text-3xl">
          {FLASH_KIND[toast.kind].icon}
        </i>
      </article>
    </div>
  );
}

function FlashMessageContent({ flash }: { flash: FlashMessage }) {
  if (typeof flash === "string") {
    return <p className="text-base font-semibold lg:text-lg">{flash}</p>;
  }

  return (
    <p className="text-base font-semibold lg:text-lg">
      {flash.message}
      {flash.link ? (
        <>
          {" "}
          <Link className="link" href={flash.link.href}>
            {flash.link.label}
          </Link>
        </>
      ) : null}
    </p>
  );
}

type FlashToastKind = keyof typeof FLASH_KIND;
type FlashToastPhase = "entering" | "visible" | "leaving";
type FlashToast = {
  flash: FlashMessage;
  kind: FlashToastKind;
  phase: FlashToastPhase;
  token: string;
};

function useFlashToast(
  activeFlash: FlashMessage | null,
  activeKind: FlashToastKind | null,
  activeToken: string,
) {
  const [toast, setToast] = useState<FlashToast | null>(null);
  const toastToken = toast?.token;
  const toastPhase = toast?.phase;

  useEffect(() => {
    if (!activeFlash || !activeKind || !activeToken) return undefined;

    setToast((current) => {
      if (current && current.token === activeToken) {
        return current;
      }

      return {
        flash: activeFlash,
        kind: activeKind,
        phase: "entering",
        token: activeToken,
      };
    });

    return undefined;
  }, [activeFlash, activeKind, activeToken]);

  useEffect(() => {
    if (toastPhase !== "entering" || !toastToken) return undefined;

    const timeout = window.setTimeout(() => {
      setToast((current) =>
        current && current.token === toastToken ? {...current, phase: "visible"} : current,
      );
    }, TOAST_ENTER_DELAY);

    return () => window.clearTimeout(timeout);
  }, [toastPhase, toastToken]);

  useEffect(() => {
    if (toastPhase !== "visible" || !toastToken) return undefined;

    const timeout = window.setTimeout(() => {
      setToast((current) =>
        current && current.token === toastToken ? {...current, phase: "leaving"} : current,
      );
    }, AUTO_DISMISS_DELAY);

    return () => window.clearTimeout(timeout);
  }, [toastPhase, toastToken]);

  useEffect(() => {
    if (toastPhase !== "leaving" || !toastToken) return undefined;

    const timeout = window.setTimeout(() => {
      setToast((current) => (current && current.token === toastToken ? null : current));
    }, TOAST_EXIT_DURATION);

    return () => window.clearTimeout(timeout);
  }, [toastPhase, toastToken]);

  return toast;
}

function flashToken(kind: FlashToastKind, flash: FlashMessage) {
  const message = flashMessageText(flash);
  const link =
    typeof flash === "string" ? "" : `${flash.link?.label ?? ""}:${flash.link?.href ?? ""}`;

  return `${kind}:${message ?? ""}:${link}`;
}

function flashMessageText(flash: FlashMessage | null) {
  return typeof flash === "string" ? flash : flash?.message;
}

function getActiveFlash(flash: {alert: FlashMessage | null; notice: FlashMessage | null}) {
  return flash.alert || flash.notice;
}

function getActiveFlashKind(flash: {alert: FlashMessage | null; notice: FlashMessage | null}) {
  if (flash.alert) return "alert" as const;
  if (flash.notice) return "notice" as const;

  return null;
}
