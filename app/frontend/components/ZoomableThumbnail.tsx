import { PhotoIcon } from "@heroicons/react/24/outline";
import { useState } from "react";

type ZoomableThumbnailProps = {
  alt: string;
  src: string | null;
};

type LoadState = "loading" | "loaded" | "failed";

export default function ZoomableThumbnail({ alt, src }: ZoomableThumbnailProps) {
  const [loadState, setLoadState] = useState<LoadState>(src ? "loading" : "failed");

  if (loadState === "failed") {
    return (
      <div
        aria-label={`Image unavailable for ${alt}`}
        className="mx-auto flex h-24 w-22 flex-col items-center justify-center gap-1 rounded-md border border-gray-200/80 bg-gray-50/80 px-2 text-center text-xs font-medium leading-tight text-gray-400/80 dark:border-gray-800 dark:bg-gray-800/50 dark:text-gray-500"
        role="img"
      >
        <PhotoIcon className="h-5 w-5 shrink-0" />
        <span>Image unavailable</span>
      </div>
    );
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
        className={`block h-[120px] w-[90px] rounded-md object-cover object-top transition-transform duration-150 ease-out zoomable ${loadState === "loaded" ? "" : "opacity-0 is-loading"
          }`}
        loading="lazy"
        onError={() => setLoadState("failed")}
        onLoad={() => setLoadState("loaded")}
        src={src ?? ""}
      />
    </div>
  );
}
