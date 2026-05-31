import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type MouseEvent,
  type SyntheticEvent,
} from "react";
import { type MediaRecord } from "../types";

type ImageGalleryProps = {
  media: MediaRecord[];
};

type LoadState = "loading" | "loaded" | "failed";

export default function ImageGallery({ media }: ImageGalleryProps) {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [mainLoadState, setMainLoadState] = useState<{
    imageId: number | null;
    state: LoadState;
  }>({
    imageId: null,
    state: "loading",
  });
  const [thumbLoadStates, setThumbLoadStates] = useState<Record<number, LoadState>>({});
  const thumbButtonRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const thumbImageRefs = useRef<(HTMLImageElement | null)[]>([]);
  const mainImageRef = useRef<HTMLImageElement | null>(null);
  const hasRenderedSelection = useRef(false);
  const hasMultipleImages = media.length > 1;
  const current = media[selectedIndex] ?? null;
  const currentImageId = current?.id ?? null;
  const setThumbLoadState = useCallback((imageId: number, state: LoadState) => {
    setThumbLoadStates((currentStates) =>
      currentStates[imageId] === state ? currentStates : { ...currentStates, [imageId]: state },
    );
  }, []);
  const prev = useCallback(() => {
    setSelectedIndex((i) => (i > 0 ? i - 1 : media.length - 1));
  }, [media.length]);
  const next = useCallback(() => {
    setSelectedIndex((i) => (i < media.length - 1 ? i + 1 : 0));
  }, [media.length]);
  const handleMainLoad = useCallback(() => {
    if (!currentImageId) return;
    setMainLoadState({ imageId: currentImageId, state: "loaded" });
  }, [currentImageId]);
  const handleMainError = useCallback(() => {
    if (!currentImageId) return;
    setMainLoadState({ imageId: currentImageId, state: "failed" });
  }, [currentImageId]);
  const handleThumbClick = useCallback((event: MouseEvent<HTMLButtonElement>) => {
    const index = Number(event.currentTarget.dataset.index);
    if (Number.isNaN(index)) return;
    setSelectedIndex(index);
  }, []);
  const handleThumbLoad = useCallback(
    (event: SyntheticEvent<HTMLImageElement>) => {
      const imageId = Number(event.currentTarget.dataset.imageId);
      if (Number.isNaN(imageId)) return;
      setThumbLoadState(imageId, "loaded");
    },
    [setThumbLoadState],
  );
  const handleThumbError = useCallback(
    (event: SyntheticEvent<HTMLImageElement>) => {
      const imageId = Number(event.currentTarget.dataset.imageId);
      if (Number.isNaN(imageId)) return;
      setThumbLoadState(imageId, "failed");
    },
    [setThumbLoadState],
  );

  useEffect(() => {
    const selectedThumb = thumbButtonRefs.current[selectedIndex];
    if (!selectedThumb) return;

    if (!hasRenderedSelection.current) {
      hasRenderedSelection.current = true;
      return;
    }

    selectedThumb.scrollIntoView({
      behavior: "smooth",
      block: "nearest",
      inline: "start",
    });
  }, [selectedIndex]);

  useEffect(() => {
    if (!current) return;

    if (mainImageRef.current?.complete && mainImageRef.current.naturalWidth > 0) {
      setMainLoadState({ imageId: current.id, state: "loaded" });
    }
  }, [current]);

  useEffect(() => {
    media.forEach((item, index) => {
      const image = thumbImageRefs.current[index];
      if (image?.complete && image.naturalWidth > 0) {
        setThumbLoadState(item.id, "loaded");
      }
    });
  }, [media, setThumbLoadState]);

  if (media.length === 0) return null;

  if (!current) return null;

  const mainIsLoaded = mainLoadState.imageId === current.id && mainLoadState.state === "loaded";
  const mainIsFailed = mainLoadState.imageId === current.id && mainLoadState.state === "failed";
  const mainIsLoading = !mainIsLoaded && !mainIsFailed;
  const mainImageClassName = hasMultipleImages
    ? "w-full h-full object-contain object-center"
    : "max-h-160 max-w-160";
  const mainImage = (
    <img
      alt={current.alt || ""}
      className={`gallery_main__image ${mainImageClassName} ${mainIsLoaded ? "" : "hidden"}`}
      key={current.preview_url}
      onError={handleMainError}
      onLoad={handleMainLoad}
      ref={mainImageRef}
      src={current.preview_url}
    />
  );

  if (!hasMultipleImages) {
    return (
      <div
        className={`gallery_viewbox mx-8 overflow-hidden rounded-lg border border-gray-100 bg-gray-50 dark:border-gray-800 dark:bg-gray-800/40 ${mainIsLoading ? "animate-pulse" : ""}`}
      >
        {mainImage}
      </div>
    );
  }

  return (
    <div className="grow flex flex-col gap-4 w-full max-w-full items-center lg:shrink-0 lg:w-150 lg:h-150 lg:flex-row">
      <div className="gallery_nav flex flex-row items-center gap-4 w-full h-auto lg:p-4 overflow-x-auto overflow-y-hidden lg:flex-col lg:w-30 lg:h-70 lg:overflow-y-scroll lg:overflow-x-hidden">
        {media.map((item, index) => (
          <button
            className={`gallery_thumb ${index === selectedIndex ? "active" : ""}`}
            aria-label={item.alt || ""}
            data-index={index}
            key={item.id}
            onClick={handleThumbClick}
            ref={(element) => {
              thumbButtonRefs.current[index] = element;
            }}
            type="button"
          >
            <div
              className={`gallery_thumb__frame ${
                (thumbLoadStates[item.id] || "loading") === "loading" ? "loading" : ""
              }`}
            >
              <img
                alt={item.alt || ""}
                className={`gallery_thumb__image w-full h-full object-cover object-center ${
                  thumbLoadStates[item.id] === "loaded" ? "" : "hidden"
                }`}
                data-image-id={item.id}
                onError={handleThumbError}
                onLoad={handleThumbLoad}
                ref={(element) => {
                  thumbImageRefs.current[index] = element;
                }}
                src={item.thumb_url}
              />
            </div>
          </button>
        ))}
      </div>

      <div className="gallery_viewbox flex relative w-full h-80 max-h-full items-center overflow-hidden rounded-lg hover:overflow-visible lg:h-full">
        <button className="gallery_btn left-0" onClick={prev} type="button">
          ←
        </button>
        <button className="gallery_btn right-0" onClick={next} type="button">
          →
        </button>
        <div className={`gallery_main__frame w-full ${mainIsLoading ? "loading" : ""}`}>
          {mainImage}
        </div>
      </div>
    </div>
  );
}
