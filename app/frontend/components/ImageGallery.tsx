import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type RefCallback,
  type RefObject,
} from "react";

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

type GalleryContextValue = {
  media: ImageGalleryMedia[];
  current: ImageGalleryMedia;
  selectedIndex: number;
  hasMultipleImages: boolean;
  loaded: ReadonlySet<number>;
  markLoaded: (id: number) => void;
  selectImage: (index: number) => void;
  showPreviousImage: () => void;
  showNextImage: () => void;
  registerImage: (id: number) => RefCallback<HTMLImageElement>;
  registerThumbnailButton: (index: number) => RefCallback<HTMLButtonElement>;
};

const GalleryContext = createContext<GalleryContextValue | null>(null);

function useGallery(): GalleryContextValue {
  const value = useContext(GalleryContext);
  if (!value) throw new Error("useGallery must be used within ImageGallery");
  return value;
}

export default function ImageGallery({ media }: ImageGalleryProps) {
  const value = useGalleryState(media);
  if (!value) return null;
  return (
    <GalleryContext.Provider value={value}>
      {value.hasMultipleImages ? <CarouselGallery /> : <SingleGallery />}
    </GalleryContext.Provider>
  );
}

function SingleGallery() {
  const { current, loaded } = useGallery();
  const isLoading = !loaded.has(current.id);
  return (
    <div
      className="gallery_viewbox gallery_viewbox--single"
      data-loading={isLoading || undefined}
    >
      <GalleryMainImage />
    </div>
  );
}

function CarouselGallery() {
  return (
    <div className="grow flex flex-col gap-4 w-full max-w-full items-center lg:shrink-0 lg:w-150 lg:h-150 lg:flex-row">
      <ThumbnailNavigation />
      <CarouselStage />
    </div>
  );
}

function ThumbnailNavigation() {
  const { media } = useGallery();
  return (
    <div className="gallery_nav flex flex-row items-center gap-4 w-full h-auto lg:p-4 overflow-x-auto overflow-y-hidden lg:flex-col lg:w-30 lg:h-70 lg:overflow-y-scroll lg:overflow-x-hidden">
      {media.map((image, index) => (
        <GalleryThumbnail image={image} index={index} key={image.id} />
      ))}
    </div>
  );
}

function GalleryThumbnail({ index, image }: { index: number; image: ImageGalleryMedia }) {
  const { selectedIndex, loaded, markLoaded, selectImage, registerImage, registerThumbnailButton } =
    useGallery();

  const isActive = index === selectedIndex;
  const isLoading = !loaded.has(image.id);
  const handleClick = useCallback(() => selectImage(index), [selectImage, index]);
  const handleLoadOrError = useCallback(
    () => markLoaded(image.id),
    [markLoaded, image.id],
  );

  return (
    <button
      aria-label={image.alt || ""}
      className="gallery_thumb"
      data-active={isActive || undefined}
      onClick={handleClick}
      ref={registerThumbnailButton(index)}
      type="button"
    >
      <div className="gallery_thumb__frame" data-loading={isLoading || undefined}>
        <img
          alt={image.alt || ""}
          className="gallery_thumb__image w-full h-full object-cover object-center"
          onError={handleLoadOrError}
          onLoad={handleLoadOrError}
          ref={registerImage(image.id)}
          src={image.thumb_url}
        />
      </div>
    </button>
  );
}

function CarouselStage() {
  const { current, loaded, showPreviousImage, showNextImage } = useGallery();
  const isLoading = !loaded.has(current.id);
  return (
    <div className="gallery_viewbox flex relative w-full h-80 max-h-full items-center overflow-hidden rounded-lg hover:overflow-visible lg:h-full">
      <button className="gallery_btn left-0" onClick={showPreviousImage} type="button">
        ←
      </button>
      <button className="gallery_btn right-0" onClick={showNextImage} type="button">
        →
      </button>
      <div className="gallery_main__frame" data-loading={isLoading || undefined}>
        <GalleryMainImage />
      </div>
    </div>
  );
}

function GalleryMainImage() {
  const { current, markLoaded, registerImage } = useGallery();
  const handleLoadOrError = useCallback(
    () => markLoaded(current.id),
    [markLoaded, current.id],
  );

  return (
    <img
      alt={current.alt || ""}
      className="gallery_main__image"
      key={current.preview_url}
      onError={handleLoadOrError}
      onLoad={handleLoadOrError}
      ref={registerImage(current.id)}
      src={current.preview_url}
    />
  );
}

function useGalleryState(media: ImageGalleryMedia[]): GalleryContextValue | null {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [loaded, setLoaded] = useState<ReadonlySet<number>>(() => new Set());
  const thumbnailButtonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  const hasMultipleImages = media.length > 1;
  const current = media[selectedIndex] ?? null;

  const markLoaded = useCallback((id: number) => {
    setLoaded((prev) => (prev.has(id) ? prev : new Set(prev).add(id)));
  }, []);

  const selectImage = useCallback(
    (index: number) => {
      if (index < 0 || index >= media.length) return;
      setSelectedIndex(index);
    },
    [media.length],
  );

  const showPreviousImage = useCallback(() => {
    setSelectedIndex((i) => previousImageIndex(i, media.length));
  }, [media.length]);

  const showNextImage = useCallback(() => {
    setSelectedIndex((i) => nextImageIndex(i, media.length));
  }, [media.length]);

  const registerImage = useCallback(
    (id: number) => (el: HTMLImageElement | null) => {
      if (el && el.complete && el.naturalWidth > 0) markLoaded(id);
    },
    [markLoaded],
  );

  const registerThumbnailButton = useCallback(
    (index: number) => (el: HTMLButtonElement | null) => {
      thumbnailButtonRefs.current[index] = el;
    },
    [],
  );

  useKeepSelectionInBounds(media.length, selectedIndex, selectImage);
  useScrollSelectedThumbnailIntoView(selectedIndex, thumbnailButtonRefs);

  if (!current) return null;

  return {
    media,
    current,
    selectedIndex,
    hasMultipleImages,
    loaded,
    markLoaded,
    selectImage,
    showPreviousImage,
    showNextImage,
    registerImage,
    registerThumbnailButton,
  };
}

function useKeepSelectionInBounds(
  imageCount: number,
  selectedIndex: number,
  selectImage: (index: number) => void,
) {
  useEffect(resetSelectionIfOutOfBounds, [imageCount, selectImage, selectedIndex]);

  function resetSelectionIfOutOfBounds() {
    if (selectedIndex >= imageCount && imageCount > 0) selectImage(0);
  }
}

function useScrollSelectedThumbnailIntoView(
  selectedIndex: number,
  thumbnailButtonRefs: RefObject<(HTMLButtonElement | null)[]>,
) {
  const hasRenderedSelection = useRef(false);

  useEffect(scrollSelectedThumbnailIntoView, [selectedIndex, thumbnailButtonRefs]);

  function scrollSelectedThumbnailIntoView() {
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
  }
}

function previousImageIndex(currentIndex: number, imageCount: number) {
  if (imageCount === 0) return 0;

  return currentIndex > 0 ? currentIndex - 1 : imageCount - 1;
}

function nextImageIndex(currentIndex: number, imageCount: number) {
  if (imageCount === 0) return 0;

  return currentIndex < imageCount - 1 ? currentIndex + 1 : 0;
}
