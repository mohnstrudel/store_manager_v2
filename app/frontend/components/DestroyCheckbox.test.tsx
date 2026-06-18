import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import DestroyCheckbox from "./DestroyCheckbox";

describe("DestroyCheckbox", () => {
  it("renders the 'Mark for deletion' label", () => {
    render(<DestroyCheckbox defaultChecked={false} name="item[_destroy]" />);

    expect(screen.getByLabelText("Mark for deletion")).toBeInTheDocument();
  });

  it("includes a hidden input with value 0 for the unchecked state", () => {
    const { container } = render(<DestroyCheckbox defaultChecked={false} name="item[_destroy]" />);

    // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
    const hidden = container.querySelector('input[type="hidden"]') as HTMLInputElement;

    expect(hidden).not.toBeNull();
    expect(hidden.value).toBe("0");
    expect(hidden.name).toBe("item[_destroy]");
  });

  it("renders the checkbox unchecked by default", () => {
    render(<DestroyCheckbox defaultChecked={false} name="item[_destroy]" />);

    expect(screen.getByRole("checkbox", { name: "Mark for deletion" })).not.toBeChecked();
  });

  it("renders the checkbox checked when defaultChecked is true", () => {
    render(<DestroyCheckbox defaultChecked={true} name="item[_destroy]" />);

    expect(screen.getByRole("checkbox", { name: "Mark for deletion" })).toBeChecked();
  });

  it("calls onChange with true when the checkbox is checked", async () => {
    const user = userEvent.setup();
    const onChange = vi.fn<(checked: boolean) => void>();

    render(<DestroyCheckbox defaultChecked={false} name="item[_destroy]" onChange={onChange} />);

    await user.click(screen.getByRole("checkbox"));

    expect(onChange).toHaveBeenCalledWith(true);
  });

  it("calls onChange with false when the checkbox is unchecked", async () => {
    const user = userEvent.setup();
    const onChange = vi.fn<(checked: boolean) => void>();

    render(<DestroyCheckbox defaultChecked={true} name="item[_destroy]" onChange={onChange} />);

    await user.click(screen.getByRole("checkbox"));

    expect(onChange).toHaveBeenCalledWith(false);
  });

  it("does not require an onChange handler", async () => {
    const user = userEvent.setup();

    render(<DestroyCheckbox defaultChecked={false} name="item[_destroy]" />);

    await user.click(screen.getByRole("checkbox"));

    expect(screen.getByRole("checkbox")).toBeChecked();
  });
});
