import { useCallback, useEffect, useState } from "react";

export function useRecentlySaved() {
  const [isSaved, setIsSaved] = useState(false);

  const markAsSaved = useCallback(() => {
    setIsSaved(true);
  }, []);

  useEffect(() => {
    if (!isSaved) return undefined;
    const timeout = window.setTimeout(() => setIsSaved(false), 2400);
    return () => window.clearTimeout(timeout);
  }, [isSaved]);

  return { isSaved, markAsSaved };
}
