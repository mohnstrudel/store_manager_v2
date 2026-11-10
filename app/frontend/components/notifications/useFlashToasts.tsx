import { usePage } from "@inertiajs/react";
import { useEffect } from "react";

import { toast } from "@/components/ui/toast";
import type { PageProps } from "@/types/inertia";

import NotificationContent from "./NotificationContent";

const FLASH_KINDS = ["alert", "notice"] as const;

export function useFlashToasts() {
  const flash = usePage<PageProps>().props.flash;

  useEffect(() => {
    if (!flash) return;

    for (const kind of FLASH_KINDS) {
      const notification = flash[kind];
      if (notification)
        toast.add({
          title: <NotificationContent notification={notification} />,
          type: kind,
        });
    }
  }, [flash]);
}
