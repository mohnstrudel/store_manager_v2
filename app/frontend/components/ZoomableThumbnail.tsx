import { useState } from "react";

type ZoomableThumbnailProps = {
  alt: string;
  src: string | null;
};

export default function ZoomableThumbnail({ alt, src }: ZoomableThumbnailProps) {
  const [isLoaded, setIsLoaded] = useState(false);

  if (!src) {
    return null;
  }

  return (
    <div className="relative flex items-center justify-center mx-auto w-[100px] h-[120px] overflow-visible">
      {!isLoaded && (
        <div
          aria-hidden="true"
          className="absolute inset-0 rounded-md bg-gray-200 dark:bg-gray-700 animate-pulse"
        />
      )}
      <img
        alt={alt}
        className={`block rounded-md w-[100px] h-[120px] object-cover object-center transition-transform duration-150 ease-out zoomable ${isLoaded ? "" : "opacity-0 is-loading"}`}
        loading="lazy"
        onLoad={() => setIsLoaded(true)}
        src={src}
      />
    </div>
  );
}
