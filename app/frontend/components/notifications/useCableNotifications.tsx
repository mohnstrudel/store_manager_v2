import { useEffect } from "react";

import { toast } from "@/components/ui/toast";

import { isCableNotification } from "./notification";
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
    }, ignoreLoadFailure);

    return () => {
      cancelled = true;
      disconnect?.();
    };
  }, [enabled]);
}

function ignoreLoadFailure() {}

function showNotification(data: unknown) {
  if (!isCableNotification(data)) return;

  const { kind, ...notification } = data;
  toast.add({
    timeout: 0,
    title: <NotificationContent notification={notification} />,
    type: kind,
  });
}
