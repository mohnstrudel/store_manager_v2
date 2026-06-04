import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import ImageGallery, { type ImageGalleryMedia } from "./ImageGallery";

const media: ImageGalleryMedia[] = [
  {
    id: 1,
    alt: "Front",
    position: 0,
    preview_url: "/front-preview.png",
    thumb_url: "/front-thumb.png",
  },
  {
    id: 2,
    alt: "Side",
    position: 1,
    preview_url: "/side-preview.png",
    thumb_url: "/side-thumb.png",
  },
  {
    id: 3,
    alt: "Back",
    position: 2,
    preview_url: "/back-preview.png",
    thumb_url: "/back-thumb.png",
  },
];

describe("ImageGallery", () => {
  const scrollIntoView = vi.fn<(...args: unknown[]) => unknown>();

  beforeEach(() => {
    scrollIntoView.mockReset();
    Object.defineProperty(Element.prototype, "scrollIntoView", {
      configurable: true,
      value: scrollIntoView,
    });
  });

  it("marks the selected thumbnail and scrolls newly selected previews into view", async () => {
    const user = userEvent.setup();

    render(<ImageGallery media={media} />);

    const firstThumb = screen.getByRole("button", { name: "Front" });
    const secondThumb = screen.getByRole("button", { name: "Side" });

    expect(firstThumb).toHaveAttribute("data-active");
    expect(secondThumb).not.toHaveAttribute("data-active");

    expect(scrollIntoView).not.toHaveBeenCalled();

    await user.click(secondThumb);

    expect(firstThumb).not.toHaveAttribute("data-active");
    expect(secondThumb).toHaveAttribute("data-active");
    expect(scrollIntoView).toHaveBeenCalledWith({
      behavior: "smooth",
      block: "nearest",
      inline: "start",
    });
  });

  it("keeps thumbnail selection in sync when stepping through images", async () => {
    const user = userEvent.setup();

    render(<ImageGallery media={media} />);

    await user.click(screen.getByRole("button", { name: "→" }));

    expect(screen.getByRole("button", { name: "Side" })).toHaveAttribute("data-active");
    expect(document.querySelector(".gallery_main__image")).toHaveAttribute(
      "src",
      "/side-preview.png",
    );
  });

  it("shows pulsing loading frames until the gallery images load", () => {
    const { container } = render(<ImageGallery media={media} />);

    const thumbFrame = container.querySelector(".gallery_thumb__frame");
    const thumbImage = container.querySelector(".gallery_thumb__frame img");
    const mainFrame = container.querySelector(".gallery_main__frame");
    const mainImage = container.querySelector(".gallery_main__frame img");

    expect(thumbFrame).toHaveAttribute("data-loading");
    expect(mainFrame).toHaveAttribute("data-loading");

    fireEvent.load(thumbImage!);
    fireEvent.load(mainImage!);

    expect(thumbFrame).not.toHaveAttribute("data-loading");
    expect(mainFrame).not.toHaveAttribute("data-loading");
  });

  it("renders a single image without carousel controls", () => {
    const { container } = render(<ImageGallery media={[media[0]]} />);

    expect(screen.getByRole("img", { name: "Front" })).toHaveClass("gallery_main__image");
    expect(screen.queryByRole("button", { name: "←" })).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "→" })).not.toBeInTheDocument();
    expect(container.querySelector(".gallery_viewbox")).toHaveClass(
      "gallery_viewbox",
      "gallery_viewbox--single",
    );
    expect(container.querySelector(".gallery_main__frame")).toBeNull();
    expect(container.querySelector(".gallery_viewbox")).toHaveAttribute("data-loading");

    fireEvent.load(screen.getByAltText("Front"));

    expect(container.querySelector(".gallery_viewbox")).not.toHaveAttribute("data-loading");
  });
});
