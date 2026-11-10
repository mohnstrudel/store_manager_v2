import { router, usePage } from "@inertiajs/react";
import { useEffect, useState } from "react";

import { toast } from "@/components/ui/toast";

import { isNotificationMessage, NOTIFICATION_KINDS } from "./notification";
import NotificationContent from "./NotificationContent";

export function useFlashToasts() {
  const { flash } = usePage();
  const [mountedFlash] = useState(flash);

  useEffect(() => {
    let lastShown: object | undefined;

    function showOnce(received: Record<string, unknown>) {
      if (received === lastShown) return;

      lastShown = received;
      showFlash(received);
    }

    showOnce(mountedFlash);

    return router.on("flash", (event) => showOnce(event.detail.flash));
  }, [mountedFlash]);
}

function showFlash(flash: Record<string, unknown>) {
  for (const kind of NOTIFICATION_KINDS) {
    const notification = flash[kind];
    if (isNotificationMessage(notification)) {
      toast.add({ title: <NotificationContent notification={notification} />, type: kind });
    }
  }
}
