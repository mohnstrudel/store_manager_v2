import { router } from "@inertiajs/react";
import { useCallback } from "react";

export function useConfirmedDestroy(path: string) {
  return useCallback(() => {
    if (window.confirm("Are you sure?")) {
      router.delete(path);
    }
  }, [path]);
}
