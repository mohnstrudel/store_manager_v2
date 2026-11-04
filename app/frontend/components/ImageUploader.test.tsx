import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import ImageUploader, { type ImageUploaderMedia } from "./ImageUploader";

vi.mock("@dnd-kit/react", () => ({
  DragDropProvider: ({ children }: { children: ReactNode }) => <div>{children}</div>,
}));

vi.mock("@dnd-kit/react/sortable", () => ({
  isSortable: () => true,
  useSortable: () => ({
    handleRef: vi.fn<(element: HTMLElement | null) => void>(),
    isDragging: false,
    ref: vi.fn<(element: HTMLElement | null) => void>(),
  }),
}));

const media: ImageUploaderMedia[] = [
  {
    id: 1,
    alt: "Front",
    image_blob_id: "existing-blob",
    position: 0,
    preview_url: "/front.png",
    thumb_url: "/front-thumb.png",
    _destroy: false,
  },
  {
    id: 2,
    alt: "Back",
    image_blob_id: "deleted-blob",
    position: 1,
    preview_url: "/back.png",
    thumb_url: "/back-thumb.png",
    _destroy: true,
  },
];

class FakeXMLHttpRequest {
  static requests: FakeXMLHttpRequest[] = [];
  static signedIds: string[] = [];

  responseText = JSON.stringify({
    signed_id: FakeXMLHttpRequest.signedIds.shift() ?? "new-signed-id",
  });
  status = 201;
  upload = new FakeEventTarget();
  private listeners = new FakeEventTarget();

  constructor() {
    FakeXMLHttpRequest.requests.push(this);
  }

  addEventListener(type: string, listener: EventListener) {
    this.listeners.addEventListener(type, listener);
  }

  open = vi.fn<(method: string, url: string) => void>();
  setRequestHeader = vi.fn<(header: string, value: string) => void>();

  send = vi.fn<() => void>(() => {
    this.upload.dispatch(
      "progress",
      new ProgressEvent("progress", {
        lengthComputable: true,
        loaded: 1,
        total: 1,
      }),
    );
    queueMicrotask(() => this.listeners.dispatch("load", new Event("load")));
  });
}

class FakeEventTarget {
  private listeners: Record<string, EventListener[]> = {};

  addEventListener(type: string, listener: EventListener) {
    this.listeners[type] = [...(this.listeners[type] ?? []), listener];
  }

  dispatch(type: string, event: Event) {
    for (const listener of this.listeners[type] ?? []) listener(event);
  }
}

describe("ImageUploader", () => {
  const createObjectURL = vi.fn<(object: Blob | MediaSource) => string>(() => "blob:preview");

  beforeEach(() => {
    FakeXMLHttpRequest.requests = [];
    FakeXMLHttpRequest.signedIds = [];
    vi.stubGlobal("XMLHttpRequest", FakeXMLHttpRequest);
    vi.stubGlobal("URL", { ...URL, createObjectURL });
    createObjectURL.mockClear();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("renders hidden fields for active and deleted images", () => {
    render(
      <ImageUploader
        media={media}
        onMediaChange={vi.fn<(media: ImageUploaderMedia[]) => void>()}
      />,
    );

    expect(document.querySelector('input[name="media[0][id]"]')).toHaveValue("1");
    expect(document.querySelector('input[name="media[0][alt]"]')).toHaveValue("Front");
    expect(document.querySelector('input[name="media[0][position]"]')).toHaveValue("0");
    expect(document.querySelector('input[name="media[0][image_blob_id]"]')).toHaveValue(
      "existing-blob",
    );
    expect(document.querySelector('input[name="media[0][_destroy]"]')).toHaveValue("0");
    expect(document.querySelector('input[name="media[1][_destroy]"]')).toHaveValue("1");
  });

  it("marks an image for deletion when removing it", async () => {
    const user = userEvent.setup();
    const onMediaChange = vi.fn<(media: ImageUploaderMedia[]) => void>();

    render(<ImageUploader media={media} onMediaChange={onMediaChange} />);

    await user.click(screen.getByRole("button", { name: "Remove image" }));

    expect(onMediaChange).toHaveBeenCalledWith([{ ...media[0], _destroy: true }, media[1]]);
  });

  it("uploads selected files and appends new media records", async () => {
    const user = userEvent.setup();
    const onMediaChange = vi.fn<(media: ImageUploaderMedia[]) => void>();
    const file = new File(["image"], "new-image.png", { type: "image/png" });

    render(<ImageUploader media={media} onMediaChange={onMediaChange} />);

    await user.upload(screen.getByTestId("new-images-input"), file);

    await waitFor(() => {
      expect(onMediaChange).toHaveBeenCalledWith([
        ...media,
        {
          alt: "",
          id: null,
          image_blob_id: "new-signed-id",
          position: 1,
          preview_url: "blob:preview",
          thumb_url: "blob:preview",
          _destroy: false,
        },
      ]);
    });
    expect(FakeXMLHttpRequest.requests[0].open).toHaveBeenCalledWith("POST", "/media/uploads");
  });

  it("uploads every selected file and appends them in selection order", async () => {
    const user = userEvent.setup();
    const onMediaChange = vi.fn<(media: ImageUploaderMedia[]) => void>();
    const files = ["one.png", "two.png", "three.png"].map(
      (name) => new File(["image"], name, { type: "image/png" }),
    );
    FakeXMLHttpRequest.signedIds = ["signed-one", "signed-two", "signed-three"];

    render(<ImageUploader media={media} onMediaChange={onMediaChange} />);

    await user.upload(screen.getByTestId("new-images-input"), files);

    const newImage = (image_blob_id: string, position: number): ImageUploaderMedia => ({
      alt: "",
      id: null,
      image_blob_id,
      position,
      preview_url: "blob:preview",
      thumb_url: "blob:preview",
      _destroy: false,
    });
    await waitFor(() => {
      expect(onMediaChange).toHaveBeenCalledWith([
        ...media,
        newImage("signed-one", 1),
        newImage("signed-two", 2),
        newImage("signed-three", 3),
      ]);
    });
    expect(onMediaChange).toHaveBeenCalledOnce();
    expect(FakeXMLHttpRequest.requests).toHaveLength(3);
  });

  it("marks uploaded but unsaved images as pending", () => {
    render(
      <ImageUploader
        media={[
          {
            alt: "",
            id: null,
            image_blob_id: "pending-signed-id",
            position: 0,
            preview_url: "blob:preview",
            thumb_url: "blob:preview",
            _destroy: false,
          },
        ]}
        onMediaChange={vi.fn<(media: ImageUploaderMedia[]) => void>()}
      />,
    );

    expect(screen.getByTestId("image-pending-badge")).toHaveTextContent("Pending");
  });
});
