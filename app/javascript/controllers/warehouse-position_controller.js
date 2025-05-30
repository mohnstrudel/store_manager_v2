import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  changePosition(event) {
    event.currentTarget.form.requestSubmit();
  }
}
