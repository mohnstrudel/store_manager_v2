import { router } from "@inertiajs/react";
import { useCallback, useEffect, useRef } from "react";

type PostMethod = (url: string, data?: Record<string, unknown>) => void;

export function useConfirmAction(
  method: "delete" | "post" | "patch" | "put",
  path: string,
  options: { data?: Record<string, unknown>; message?: string } = {},
) {
  const { data, message = "Are you sure?" } = options;
  const dataRef = useRef(data);
  useEffect(function syncDataRef() {
    dataRef.current = data;
  });

  return useCallback(() => {
    if (window.confirm(message)) {
      if (method === "delete") {
        router.delete(path);
      } else {
        (router[method] as PostMethod)(path, dataRef.current);
      }
    }
  }, [message, method, path]);
}
