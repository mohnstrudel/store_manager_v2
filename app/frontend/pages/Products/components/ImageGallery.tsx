import { useEffect, useRef, useState } from "react";
import { type MediaRecord } from "../types";

type ImageGalleryProps = {
  media: MediaRecord[];
};

export default function ImageGallery({ media }: ImageGalleryProps) {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const thumbRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const hasRenderedSelection = useRef(false);

  useEffect(() => {
    const selectedThumb = thumbRefs.current[selectedIndex];
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

  if (media.length === 0) return null;

  const current = media[selectedIndex];

  function prev() {
    setSelectedIndex((i) => (i > 0 ? i - 1 : media.length - 1));
  }

  function next() {
    setSelectedIndex((i) => (i < media.length - 1 ? i + 1 : 0));
  }

  if (media.length === 1) {
    return (
      <div className="w-full max-w-full items-center flex flex-col gap-4">
        <div className="gallery-viewbox flex relative w-full max-h-full items-center overflow-hidden rounded-lg">
          <img
            alt={current.alt || ""}
            className="w-full h-auto object-contain object-center"
            src={current.preview_url}
          />
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4 w-full max-w-full items-center lg:flex-row lg:shrink-0 lg:w-150 lg:h-150">
      <div className="gallery-nav flex flex-row items-center gap-4 w-full h-auto lg:p-4 overflow-x-auto overflow-y-hidden lg:flex-col lg:w-30 lg:h-70 lg:overflow-y-scroll lg:overflow-x-hidden">
        {media.map((item, index) => (
          <button
            className={`gallery-thumb ${index === selectedIndex ? "active" : ""}`}
            key={item.id}
            onClick={() => setSelectedIndex(index)}
            ref={(element) => {
              thumbRefs.current[index] = element;
            }}
            type="button"
          >
            <div className="gallery-thumb__frame">
              <img
                alt={item.alt || ""}
                className="gallery-thumb__image w-full h-full object-cover"
                src={item.thumb_url}
              />
            </div>
          </button>
        ))}
      </div>

      <div className="gallery-viewbox flex relative w-full max-h-full items-center overflow-hidden rounded-lg hover:overflow-visible lg:h-full">
        <button className="gallery-btn left-0" onClick={prev} type="button">
          ←
        </button>
        <button className="gallery-btn right-0" onClick={next} type="button">
          →
        </button>
        <div className="gallery-main__frame w-full">
          <img
            alt={current.alt || ""}
            className="gallery-main__image w-full h-auto object-contain object-center"
            key={current.id}
            src={current.preview_url}
          />
        </div>
      </div>
    </div>
  );
}
