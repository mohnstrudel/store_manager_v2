import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import ZoomableThumbnail from "./ZoomableThumbnail";

describe("ZoomableThumbnail", () => {
  it("renders a lazy zoomable thumbnail and clears the skeleton after load", async () => {
    render(<ZoomableThumbnail alt="Pikachu" src="/thumb.png" />);

    const image = screen.getByRole("img", { name: "Pikachu" });
    expect(image).toHaveAttribute("loading", "lazy");
    expect(image).toHaveAttribute("src", "/thumb.png");
    expect(image).toHaveClass("zoomable");
    expect(image).toHaveClass("is-loading");

    fireEvent.load(image);

    await waitFor(() => {
      expect(image).not.toHaveClass("is-loading");
    });
  });

  it("renders a fallback placeholder without an image", () => {
    render(<ZoomableThumbnail alt="Pikachu" src={null} />);

    expect(screen.getByRole("img", { name: "Image unavailable for Pikachu" })).toBeInTheDocument();
    expect(screen.getByText("Image unavailable")).toBeInTheDocument();
    expect(screen.queryByRole("img", { name: "Pikachu" })).not.toBeInTheDocument();
  });

  it("replaces a broken image with the fallback placeholder", async () => {
    render(<ZoomableThumbnail alt="Pikachu" src="/thumb.png" />);

    const image = screen.getByRole("img", { name: "Pikachu" });
    fireEvent.error(image);

    await waitFor(() => {
      expect(
        screen.getByRole("img", { name: "Image unavailable for Pikachu" }),
      ).toBeInTheDocument();
    });

    expect(screen.getByText("Image unavailable")).toBeInTheDocument();
    expect(screen.queryByRole("img", { name: "Pikachu" })).not.toBeInTheDocument();
  });
});
