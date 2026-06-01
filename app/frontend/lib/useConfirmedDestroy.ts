import { router } from "@inertiajs/react";
import { useCallback } from "react";

export function useConfirmedDestroy(path: string, message = "Are you sure?") {
  return useCallback(() => {
    if (window.confirm(message)) {
      router.delete(path);
    }
  }, [message, path]);
}
