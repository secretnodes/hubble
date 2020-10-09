import { Controller } from 'stimulus';
import StimulusReflex from 'stimulus_reflex';

export default class extends Controller {
  connect() {
    this.load();
    StimulusReflex.register(this)
  }

  toggleNew() {
    $('.new-comment-container').toggleClass('d-none');
    $('.comments').toggleClass('d-none');
  }
}