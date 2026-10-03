export function connect(url, onOpen, onMessage, onClose) {
  const ws = new WebSocket(url);
  ws.onopen = () => onOpen(ws);
  ws.onmessage = (event) => onMessage(event.data);
  ws.onclose = () => onClose();
}

export function send(ws, text) {
  ws.send(text);
}

export function after(ms, callback) {
  setTimeout(callback, ms);
}
