import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import StoreInfoFields from "./StoreInfoFields";
import { type StoreInfoFormData } from "../types";

type MockOption = {
  value: string;
  label: string;
};

type SmartSelectMockProps = {
  defaultValue: MockOption | null;
  isClearable?: boolean;
  name: string;
  options: MockOption[];
};

type TagSelectMockProps = {
  defaultValue: MockOption[];
  delimiter?: string;
  name: string;
};

vi.mock("@/components/SmartSelect", () => ({
  default: ({ defaultValue, name, options, isClearable = false }: SmartSelectMockProps) => {
    const key = (o: MockOption) => String(o.value);
    return (
      <>
        <input name={name} type="hidden" value={defaultValue?.value ?? ""} />
        <select defaultValue={defaultValue != null ? key(defaultValue) : ""}>
          {isClearable && <option value="">—</option>}
          {options.map((o) => (
            <option key={key(o)} value={key(o)}>
              {o.label}
            </option>
          ))}
        </select>
      </>
    );
  },
}));

vi.mock("@/components/TagSelect", () => ({
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

function makeStoreInfo(overrides: Partial<StoreInfoFormData> = {}): StoreInfoFormData {
  return { id: null, store_name: "", tag_list: "", _destroy: false, ...overrides };
}

function renderStoreInfo(storeInfo: StoreInfoFormData, props: Record<string, unknown> = {}) {
  const onRemove = vi.fn();
  render(
    <StoreInfoFields
      index={0}
      onRemove={onRemove}
      storeInfo={storeInfo}
      storeNames={storeNames}
      {...props}
    />,
  );
  return { onRemove };
}

describe("StoreInfoFields", () => {
  describe("title", () => {
    it("shows 'New Store Info' for a new store info", () => {
      renderStoreInfo(makeStoreInfo());
      expect(screen.getByRole("heading", { level: 6 })).toHaveTextContent("New Store Info");
    });

    it("shows capitalized store_name as title for existing store info", () => {
      renderStoreInfo(makeStoreInfo({ id: 1, store_name: "shopify" }));
      expect(screen.getByRole("heading", { level: 6 })).toHaveTextContent("Shopify");
    });
  });

  describe("controls", () => {
    it("shows Remove button for new store info and calls onRemove on click", () => {
      const { onRemove } = renderStoreInfo(makeStoreInfo());
      fireEvent.click(screen.getByRole("button", { name: "Remove" }));
      expect(onRemove).toHaveBeenCalledWith(0);
    });

    it("shows Destroy connection? checkbox for existing store info", () => {
      renderStoreInfo(makeStoreInfo({ id: 1, store_name: "shopify" }));
      expect(screen.getByLabelText("Destroy connection?")).toBeInTheDocument();
      expect(screen.queryByRole("button", { name: "Remove" })).not.toBeInTheDocument();
    });

    it("renders Rails-style destroy inputs for existing store info", () => {
      renderStoreInfo(makeStoreInfo({ id: 1, store_name: "shopify" }));
      const checkbox = screen.getByLabelText("Destroy connection?");

      expect(
        document.querySelector('input[name="store_infos[0][_destroy]"][type="hidden"]'),
      ).toHaveValue("0");
      expect(checkbox).toHaveAttribute("name", "store_infos[0][_destroy]");
      expect(checkbox).toHaveAttribute("value", "1");
    });
  });

  describe("Store select", () => {
    it("renders a named select bridge for new store info", () => {
      renderStoreInfo(makeStoreInfo());
      expect(screen.getByRole("combobox")).toBeInTheDocument();
      expect(document.querySelector('input[name="store_infos[0][store_name]"]')).toHaveValue("");
    });

    it("renders text and a hidden store_name for existing store info", () => {
      renderStoreInfo(makeStoreInfo({ id: 1, store_name: "shopify" }));
      expect(screen.queryByRole("combobox")).not.toBeInTheDocument();
      expect(document.querySelector('input[name="store_infos[0][store_name]"]')).toHaveValue(
        "shopify",
      );
    });
  });

  describe("tags", () => {
    it("renders existing tags from the tag_list string", () => {
      renderStoreInfo(makeStoreInfo({ tag_list: "featured, new-arrival" }));
      expect(screen.getByText("featured")).toBeInTheDocument();
      expect(screen.getByText("new-arrival")).toBeInTheDocument();
      expect(document.querySelector('input[name="store_infos[0][tag_list]"]')).toHaveValue(
        "featured, new-arrival",
      );
    });
  });
});
