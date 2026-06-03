import { useCallback, useEffect, useRef, useState, type RefCallback, type RefObject } from "react";

export type ImageGalleryMedia = {
  id: number;
  alt: string;
  position?: number;
  preview_url: string;
  thumb_url: string;
};

type ImageGalleryProps = {
  media: ImageGalleryMedia[];
};

type LoadState = "loading" | "loaded" | "failed";

type MainLoadState = {
  imageId: number | null;
  state: LoadState;
};

type ImageGalleryBehavior = {
  current: ImageGalleryMedia | null;
  hasMultipleImages: boolean;
  mainImageRef: RefObject<HTMLImageElement | null>;
  mainIsLoaded: boolean;
  mainIsLoading: boolean;
  markMainImageFailed: () => void;
  markMainImageLoaded: () => void;
  markThumbnailFailed: (imageId: number) => void;
  markThumbnailLoaded: (imageId: number) => void;
  selectImage: (index: number) => void;
  selectedIndex: number;
  setThumbnailButtonRef: (index: number) => RefCallback<HTMLButtonElement>;
  setThumbnailImageRef: (index: number) => RefCallback<HTMLImageElement>;
  showNextImage: () => void;
  showPreviousImage: () => void;
  thumbnailLoadStates: Record<number, LoadState>;
};

type GalleryWithCurrentImage = ImageGalleryBehavior & {
  current: ImageGalleryMedia;
};

export default function ImageGallery({ media }: ImageGalleryProps) {
  const gallery = useImageGallery(media);

  if (!hasCurrentImage(gallery)) return null;

  if (!gallery.hasMultipleImages) return <SingleImageGallery gallery={gallery} />;

  return <CarouselImageGallery gallery={gallery} media={media} />;
}

function SingleImageGallery({ gallery }: { gallery: GalleryWithCurrentImage }) {
  const loadingClassName = gallery.mainIsLoading ? "animate-pulse" : "";

  return (
    <div
      className={`gallery_viewbox mx-8 overflow-hidden rounded-lg border border-gray-100 bg-gray-50 dark:border-gray-800 dark:bg-gray-800/40 ${loadingClassName}`}
    >
      <GalleryMainImage gallery={gallery} layout="single" />
    </div>
  );
}

function CarouselImageGallery({
  gallery,
  media,
}: {
  gallery: GalleryWithCurrentImage;
  media: ImageGalleryMedia[];
}) {
  return (
    <div className="grow flex flex-col gap-4 w-full max-w-full items-center lg:shrink-0 lg:w-150 lg:h-150 lg:flex-row">
      <ThumbnailNavigation gallery={gallery} media={media} />
      <CarouselStage gallery={gallery} />
    </div>
  );
}

function ThumbnailNavigation({
  gallery,
  media,
}: {
  gallery: GalleryWithCurrentImage;
  media: ImageGalleryMedia[];
}) {
  return (
    <div className="gallery_nav flex flex-row items-center gap-4 w-full h-auto lg:p-4 overflow-x-auto overflow-y-hidden lg:flex-col lg:w-30 lg:h-70 lg:overflow-y-scroll lg:overflow-x-hidden">
      {media.map((image, index) => (
        <GalleryThumbnail gallery={gallery} image={image} index={index} key={image.id} />
      ))}
    </div>
  );
}

function GalleryThumbnail({
  gallery,
  image,
  index,
}: {
  gallery: GalleryWithCurrentImage;
  image: ImageGalleryMedia;
  index: number;
}) {
  const loadState = gallery.thumbnailLoadStates[image.id] ?? "loading";
  const loadingClassName = loadState === "loading" ? "loading" : "";
  const selectedClassName = index === gallery.selectedIndex ? "active" : "";
  const visibleClassName = loadState === "loaded" ? "" : "hidden";

  const handleClick = useCallback(() => {
    gallery.selectImage(index);
  }, [gallery, index]);

  const handleError = useCallback(() => {
    gallery.markThumbnailFailed(image.id);
  }, [gallery, image.id]);

  const handleLoad = useCallback(() => {
    gallery.markThumbnailLoaded(image.id);
  }, [gallery, image.id]);

  return (
    <button
      aria-label={image.alt || ""}
      className={`gallery_thumb ${selectedClassName}`}
      onClick={handleClick}
      ref={gallery.setThumbnailButtonRef(index)}
      type="button"
    >
      <div className={`gallery_thumb__frame ${loadingClassName}`}>
        <img
          alt={image.alt || ""}
          className={`gallery_thumb__image w-full h-full object-cover object-center ${visibleClassName}`}
          onError={handleError}
          onLoad={handleLoad}
          ref={gallery.setThumbnailImageRef(index)}
          src={image.thumb_url}
        />
      </div>
    </button>
  );
}

function CarouselStage({ gallery }: { gallery: GalleryWithCurrentImage }) {
  const loadingClassName = gallery.mainIsLoading ? "loading" : "";

  return (
    <div className="gallery_viewbox flex relative w-full h-80 max-h-full items-center overflow-hidden rounded-lg hover:overflow-visible lg:h-full">
      <button className="gallery_btn left-0" onClick={gallery.showPreviousImage} type="button">
        ←
      </button>
      <button className="gallery_btn right-0" onClick={gallery.showNextImage} type="button">
        →
      </button>
      <div className={`gallery_main__frame w-full ${loadingClassName}`}>
        <GalleryMainImage gallery={gallery} layout="carousel" />
      </div>
    </div>
  );
}

function GalleryMainImage({
  gallery,
  layout,
}: {
  gallery: GalleryWithCurrentImage;
  layout: "carousel" | "single";
}) {
  const imageClassName =
    layout === "carousel" ? "w-full h-full object-contain object-center" : "max-h-160 max-w-160";
  const visibleClassName = gallery.mainIsLoaded ? "" : "hidden";

  return (
    <img
      alt={gallery.current.alt || ""}
      className={`gallery_main__image ${imageClassName} ${visibleClassName}`}
      key={gallery.current.preview_url}
      onError={gallery.markMainImageFailed}
      onLoad={gallery.markMainImageLoaded}
      ref={gallery.mainImageRef}
      src={gallery.current.preview_url}
    />
  );
}

function useImageGallery(media: ImageGalleryMedia[]): ImageGalleryBehavior {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [thumbnailLoadStates, setThumbnailLoadStates] = useState<Record<number, LoadState>>({});
  const [mainLoadState, setMainLoadState] = useState<MainLoadState>({
    imageId: null,
    state: "loading",
  });
  const thumbnailButtonRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const thumbnailImageRefs = useRef<(HTMLImageElement | null)[]>([]);
  const mainImageRef = useRef<HTMLImageElement | null>(null);

  const hasMultipleImages = media.length > 1;
  const current = media[selectedIndex] ?? null;
  const currentImageId = current?.id ?? null;

  const setThumbnailLoadState = useCallback((imageId: number, state: LoadState) => {
    setThumbnailLoadStates((currentStates) =>
      currentStates[imageId] === state ? currentStates : { ...currentStates, [imageId]: state },
    );
  }, []);

  const selectImage = useCallback(
    (index: number) => {
      if (index < 0 || index >= media.length) return;

      setSelectedIndex(index);
    },
    [media.length],
  );

  const showPreviousImage = useCallback(() => {
    setSelectedIndex((currentIndex) => previousImageIndex(currentIndex, media.length));
  }, [media.length]);

  const showNextImage = useCallback(() => {
    setSelectedIndex((currentIndex) => nextImageIndex(currentIndex, media.length));
  }, [media.length]);

  const markMainImageLoaded = useCallback(() => {
    if (currentImageId == null) return;

    setMainLoadState({ imageId: currentImageId, state: "loaded" });
  }, [currentImageId]);

  const markMainImageFailed = useCallback(() => {
    if (currentImageId == null) return;

    setMainLoadState({ imageId: currentImageId, state: "failed" });
  }, [currentImageId]);

  const markThumbnailLoaded = useCallback(
    (imageId: number) => {
      setThumbnailLoadState(imageId, "loaded");
    },
    [setThumbnailLoadState],
  );

  const markThumbnailFailed = useCallback(
    (imageId: number) => {
      setThumbnailLoadState(imageId, "failed");
    },
    [setThumbnailLoadState],
  );

  const setThumbnailButtonRef = useCallback(
    (index: number) => (element: HTMLButtonElement | null) => {
      thumbnailButtonRefs.current[index] = element;
    },
    [],
  );

  const setThumbnailImageRef = useCallback(
    (index: number) => (element: HTMLImageElement | null) => {
      thumbnailImageRefs.current[index] = element;
    },
    [],
  );

  useKeepSelectionInBounds(media.length, selectImage, selectedIndex);
  useScrollSelectedThumbnailIntoView(selectedIndex, thumbnailButtonRefs);
  useMarkCachedMainImageLoaded(current, mainImageRef, markMainImageLoaded);
  useMarkCachedThumbnailImagesLoaded(media, markThumbnailLoaded, thumbnailImageRefs);

  const mainIsLoaded = currentImageHasLoaded(mainLoadState, currentImageId);
  const mainIsLoading = currentImageIsLoading(mainLoadState, currentImageId);

  return {
    current,
    hasMultipleImages,
    mainImageRef,
    mainIsLoaded,
    mainIsLoading,
    markMainImageFailed,
    markMainImageLoaded,
    markThumbnailFailed,
    markThumbnailLoaded,
    selectImage,
    selectedIndex,
    setThumbnailButtonRef,
    setThumbnailImageRef,
    showNextImage,
    showPreviousImage,
    thumbnailLoadStates,
  };
}

function useKeepSelectionInBounds(
  imageCount: number,
  selectImage: (index: number) => void,
  selectedIndex: number,
) {
  useEffect(() => {
    if (selectedIndex >= imageCount && imageCount > 0) selectImage(0);
  }, [imageCount, selectImage, selectedIndex]);
}

function useScrollSelectedThumbnailIntoView(
  selectedIndex: number,
  thumbnailButtonRefs: RefObject<(HTMLButtonElement | null)[]>,
) {
  const hasRenderedSelection = useRef(false);

  useEffect(() => {
    const selectedThumbnail = thumbnailButtonRefs.current[selectedIndex];
    if (!selectedThumbnail) return;

    if (!hasRenderedSelection.current) {
      hasRenderedSelection.current = true;
      return;
    }

    selectedThumbnail.scrollIntoView({
      behavior: "smooth",
      block: "nearest",
      inline: "start",
    });
  }, [selectedIndex, thumbnailButtonRefs]);
}

function useMarkCachedMainImageLoaded(
  current: ImageGalleryMedia | null,
  mainImageRef: RefObject<HTMLImageElement | null>,
  markMainImageLoaded: () => void,
) {
  useEffect(() => {
    if (!current) return;
    if (!hasLoadedImage(mainImageRef.current)) return;

    markMainImageLoaded();
  }, [current, mainImageRef, markMainImageLoaded]);
}

function useMarkCachedThumbnailImagesLoaded(
  media: ImageGalleryMedia[],
  markThumbnailLoaded: (imageId: number) => void,
  thumbnailImageRefs: RefObject<(HTMLImageElement | null)[]>,
) {
  useEffect(() => {
    media.forEach((image, index) => {
      if (hasLoadedImage(thumbnailImageRefs.current[index])) markThumbnailLoaded(image.id);
    });
  }, [media, markThumbnailLoaded, thumbnailImageRefs]);
}

function hasCurrentImage(gallery: ImageGalleryBehavior): gallery is GalleryWithCurrentImage {
  return gallery.current != null;
}

function hasLoadedImage(image: HTMLImageElement | null) {
  return image != null && image.complete && image.naturalWidth > 0;
}

function currentImageHasLoaded(loadState: MainLoadState, imageId: number | null) {
  return imageId != null && loadState.imageId === imageId && loadState.state === "loaded";
}

function currentImageIsLoading(loadState: MainLoadState, imageId: number | null) {
  return imageId != null && (loadState.imageId !== imageId || loadState.state === "loading");
}

function previousImageIndex(currentIndex: number, imageCount: number) {
  if (imageCount === 0) return 0;

  return currentIndex > 0 ? currentIndex - 1 : imageCount - 1;
}

function nextImageIndex(currentIndex: number, imageCount: number) {
  if (imageCount === 0) return 0;

  return currentIndex < imageCount - 1 ? currentIndex + 1 : 0;
}
