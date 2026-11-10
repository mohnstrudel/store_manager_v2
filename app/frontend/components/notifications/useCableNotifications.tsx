import { useEffect } from "react";

import { toast } from "@/components/ui/toast";
import type { FlashMessage } from "@/types/inertia";

import NotificationContent from "./NotificationContent";

export function useCableNotifications(enabled: boolean) {
  useEffect(() => {
    if (!enabled) return undefined;

    let disconnect: (() => void) | undefined;
    let cancelled = false;

    void import("@rails/actioncable").then(({ createConsumer }) => {
      if (cancelled) return;

      const consumer = createConsumer();
      consumer.subscriptions.create("NotificationsChannel", {
        received: showNotification,
      });
      disconnect = () => consumer.disconnect();
    });

    return () => {
      cancelled = true;
      disconnect?.();
    };
  }, [enabled]);
}

function showNotification({ kind, ...notification }: CableNotification) {
  toast.add({
    timeout: 0,
    title: <NotificationContent notification={notification} />,
    type: kind,
  });
}

type CableNotification = Exclude<FlashMessage, string> & {
  kind: "alert" | "notice";
};
