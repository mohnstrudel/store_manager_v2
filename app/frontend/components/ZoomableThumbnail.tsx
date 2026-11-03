import { useCallback, useState } from "react";

import ImageUnavailable from "./ImageUnavailable";

type ZoomableThumbnailProps = {
  alt: string;
  src: string | null;
};

type LoadState = "loading" | "loaded" | "failed";

export default function ZoomableThumbnail({ alt, src }: ZoomableThumbnailProps) {
  const [loadState, setLoadState] = useState<LoadState>(src ? "loading" : "failed");

  const handleError = useCallback(() => {
    setLoadState("failed");
  }, []);

  const handleLoad = useCallback(() => {
    setLoadState("loaded");
  }, []);

  if (loadState === "failed") {
    return <ImageUnavailable alt={alt} className="mx-auto h-24 w-22" />;
  }

  return (
    <div className="relative mx-auto flex h-[120px] w-[90px] items-center justify-center overflow-visible">
      {loadState === "loading" && (
        <div
          aria-hidden="true"
          className="absolute inset-0 rounded-md bg-gray-200 dark:bg-gray-700 animate-pulse"
        />
      )}
      <img
        alt={alt}
        className={`block h-[120px] w-[90px] rounded-md object-cover object-top transition-transform duration-150 ease-out zoomable ${
          loadState === "loaded" ? "" : "opacity-0 is-loading"
        }`}
        loading="lazy"
        onError={handleError}
        onLoad={handleLoad}
        src={src ?? ""}
      />
    </div>
  );
}
