import { Toaster } from "@/components/ui/toast";

import { useCableNotifications } from "./useCableNotifications";
import { useFlashToasts } from "./useFlashToasts";

export default function Notifications({ live = false }: { live?: boolean }) {
  useFlashToasts();
  useCableNotifications(live);

  return <Toaster />;
}
