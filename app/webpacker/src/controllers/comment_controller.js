import { Controller } from 'stimulus';

export default class extends Controller {
  connect() {
  }

  toggleNew() {
    $('.new-comment-container').toggleClass('d-none');
    $('.comments').toggleClass('d-none');
  }
}