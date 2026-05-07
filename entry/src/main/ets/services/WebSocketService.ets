import webSocket from '@ohos.net.webSocket';
import { apiService } from './ApiService';

export class WebSocketService {
  private ws: webSocket.WebSocket | null = null;
  private isConnected: boolean = false;
  private reconnectAttempts: number = 0;
  private maxReconnectAttempts: number = 5;
  private listeners: ((data: string) => void)[] = [];

  connect(): void {
    if (this.isConnected) {
      return;
    }

    let token = apiService.getToken();
    if (!token) {
      console.warn('WebSocket: No token available');
      return;
    }

    this.ws = webSocket.createWebSocket();
    let wsUrl = `ws://localhost:8080/ws/devices/sync`;

    this.ws.on('open', (err, value) => {
      if (err) {
        console.error('WebSocket open error:', JSON.stringify(err));
        return;
      }
      this.isConnected = true;
      this.reconnectAttempts = 0;
      console.info('WebSocket connected');

      this.ws?.send(JSON.stringify({
        action: 'auth',
        token: token
      }));
    });

    this.ws.on('message', (err, value) => {
      if (err) {
        console.error('WebSocket message error:', JSON.stringify(err));
        return;
      }
      let message = value instanceof ArrayBuffer ? this.arrayBufferToString(value) : String(value);
      this.notifyListeners(message);
    });

    this.ws.on('close', (err, value) => {
      this.isConnected = false;
      console.info('WebSocket closed');
      this.attemptReconnect();
    });

    this.ws.on('error', (err) => {
      console.error('WebSocket error:', JSON.stringify(err));
      this.isConnected = false;
    });

    this.ws.connect(wsUrl);
  }

  disconnect(): void {
    if (this.ws) {
      this.isConnected = false;
      this.ws.close();
      this.ws = null;
    }
  }

  send(data: object): void {
    if (this.isConnected && this.ws) {
      this.ws.send(JSON.stringify(data));
    }
  }

  ping(): void {
    this.send({ action: 'ping', timestamp: Date.now() });
  }

  addListener(listener: (data: string) => void): void {
    this.listeners.push(listener);
  }

  removeListener(listener: (data: string) => void): void {
    let index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyListeners(data: string): void {
    for (let listener of this.listeners) {
      listener(data);
    }
  }

  private attemptReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.warn('Max reconnect attempts reached');
      return;
    }

    this.reconnectAttempts++;
    let delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);

    setTimeout(() => {
      console.info(`Reconnecting... attempt ${this.reconnectAttempts}`);
      this.connect();
    }, delay);
  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    let uint8Array = new Uint8Array(buffer);
    let result = '';
    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i]);
    }
    return decodeURIComponent(encodeURIComponent(result));
  }
}

export let webSocketService = new WebSocketService();