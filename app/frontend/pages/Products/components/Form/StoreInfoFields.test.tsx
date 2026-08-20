import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { makeStoreInfoForm } from "../../test/factories";
import StoreInfoFields from "./StoreInfoFields";

type TagSelectMockProps = {
  defaultValue: { value: string; label: string }[];
  delimiter?: string;
  name: string;
};

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

vi.mock("./TagSelect", () => ({
  default: ({ defaultValue, delimiter = ",", name }: TagSelectMockProps) => (
    <>
      <input name={name} type="hidden" value={defaultValue.map((v) => v.value).join(delimiter)} />
      <ul>
        {defaultValue.map((v) => (
          <li key={v.value}>{v.label}</li>
        ))}
      </ul>
    </>
  ),
}));

const storeNames = ["shopify", "woo"];

describe("Products/components/Form/StoreInfoFields", () => {
  describe("title", () => {
    it("shows 'New Store Info' for a new store info", async () => {
      await renderStoreInfo(makeStoreInfoForm());

      expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("New Store Info");
    });

    it("shows capitalized store_name as title for existing store info", async () => {
      await renderStoreInfo(makeStoreInfoForm({ id: 1, store_name: "shopify" }));

      expect(screen.getByRole("heading", { level: 4 })).toHaveTextContent("Shopify");
    });
  });

  describe("controls", () => {
    it("shows Cancel button for new store info and calls onRemove on click", async () => {
      const user = userEvent.setup();
      const { onRemove } = await renderStoreInfo(makeStoreInfoForm());

      await user.click(screen.getByRole("button", { name: "Cancel" }));

      expect(onRemove).toHaveBeenCalled();
    });

    it("shows Mark for deletion checkbox for existing store info", async () => {
      await renderStoreInfo(makeStoreInfoForm({ id: 1, store_name: "shopify" }));

      expect(screen.getByLabelText("Mark for deletion")).toBeInTheDocument();
      expect(screen.queryByRole("button", { name: "Cancel" })).not.toBeInTheDocument();
    });

    it("renders Rails-style destroy inputs with the red checkbox styling", async () => {
      await renderStoreInfo(makeStoreInfoForm({ id: 1, store_name: "shopify" }));

      const checkbox = screen.getByLabelText("Mark for deletion");

      expect(
        document.querySelector('input[name="store_infos[0][_destroy]"][type="hidden"]'),
      ).toHaveValue("0");
      expect(checkbox).toHaveAttribute("name", "store_infos[0][_destroy]");
      expect(checkbox).toHaveAttribute("value", "1");
      expect(checkbox).toHaveClass("red");
      expect(checkbox).not.toHaveClass("w-4");
      expect(checkbox).not.toHaveClass("h-4");
    });

    it("applies opacity-50 class when marked for deletion", async () => {
      const user = userEvent.setup();
      const { container } = await renderStoreInfo(
        makeStoreInfoForm({ id: 1, store_name: "shopify" }),
      );

      await user.click(screen.getByLabelText("Mark for deletion"));

      expect(container.firstChild).toHaveClass("opacity-50");
    });
  });

  describe("Store select", () => {
    it("renders a named select bridge for new store info", async () => {
      await renderStoreInfo(makeStoreInfoForm());

      expect(screen.getByRole("combobox")).toBeInTheDocument();
      expect(document.querySelector('input[name="store_infos[0][store_name]"]')).toHaveValue("");
    });

    it("renders a disabled select and a hidden store_name for existing store info", async () => {
      await renderStoreInfo(makeStoreInfoForm({ id: 1, store_name: "shopify" }));

      expect(screen.getByRole("combobox")).toBeDisabled();
      expect(document.querySelector('input[name="store_infos[0][store_name]"]')).toHaveValue(
        "shopify",
      );
    });
  });

  describe("tags", () => {
    it("renders existing tags from the tag_list string", async () => {
      await renderStoreInfo(makeStoreInfoForm({ tag_list: "featured, new-arrival" }));

      expect(screen.getByText("featured")).toBeInTheDocument();
      expect(screen.getByText("new-arrival")).toBeInTheDocument();
      expect(document.querySelector('input[name="store_infos[0][tag_list]"]')).toHaveValue(
        "featured, new-arrival",
      );
    });
  });
});

async function renderStoreInfo(
  storeInfo: ReturnType<typeof makeStoreInfoForm>,
  props: Record<string, unknown> = {},
) {
  const onRemove = vi.fn<(index: number) => void>();
  const result = render(
    <StoreInfoFields
      index={0}
      onRemove={onRemove}
      storeInfo={storeInfo}
      storeNames={storeNames}
      {...props}
    />,
  );
  await act(async () => {});
  return { ...result, onRemove };
}
