import { Events } from "@wailsio/runtime";

export function on(name, callback) {
  Events.On(name, (event) => callback(event.data));
}

export function emit(name, data) {
  Events.Emit(name, data);
}
