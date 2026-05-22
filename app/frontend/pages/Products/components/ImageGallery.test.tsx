import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import ImageGallery from "./ImageGallery";
import { type MediaRecord } from "../types";

const media: MediaRecord[] = [
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
  beforeEach(() => {
    Element.prototype.scrollIntoView = vi.fn();
  });

  it("marks the selected thumbnail and scrolls newly selected previews into view", async () => {
    const user = userEvent.setup();

    render(<ImageGallery media={media} />);

    const firstThumb = screen.getByRole("button", { name: "Front" });
    const secondThumb = screen.getByRole("button", { name: "Side" });

    expect(firstThumb).toHaveClass("active");
    expect(secondThumb).not.toHaveClass("active");
    expect(Element.prototype.scrollIntoView).not.toHaveBeenCalled();

    await user.click(secondThumb);

    expect(firstThumb).not.toHaveClass("active");
    expect(secondThumb).toHaveClass("active");
    expect(Element.prototype.scrollIntoView).toHaveBeenCalledWith({
      behavior: "smooth",
      block: "nearest",
      inline: "start",
    });
  });

  it("keeps thumbnail selection in sync when stepping through images", async () => {
    const user = userEvent.setup();

    render(<ImageGallery media={media} />);

    await user.click(screen.getByRole("button", { name: "→" }));

    expect(screen.getByRole("button", { name: "Side" })).toHaveClass("active");
    expect(document.querySelector(".gallery-main__image")).toHaveAttribute(
      "src",
      "/side-preview.png",
    );
  });
});
