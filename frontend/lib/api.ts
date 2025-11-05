/**
 * API client for making requests to the backend
 */
import axios, { AxiosError, AxiosInstance } from 'axios';
import type {
  AuthResponse,
  LoginCredentials,
  RegisterData,
  User,
  Room,
  RoomCreate,
  RoomUpdate,
  Message,
  MessageCreate,
  Note,
  NoteCreate,
  NoteUpdate,
  APIError,
} from './types';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

// Create axios instance
const api: AxiosInstance = axios.create({
  baseURL: `${API_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error: AxiosError<APIError>) => {
    if (error.response?.status === 401) {
      // Unauthorized - clear token and redirect to login
      localStorage.removeItem('access_token');
      if (typeof window !== 'undefined') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// ==========================================
// Authentication APIs
// ==========================================

export const authAPI = {
  async register(data: RegisterData): Promise<User> {
    const response = await api.post<User>('/auth/register', data);
    return response.data;
  },

  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const formData = new URLSearchParams();
    formData.append('username', credentials.username);
    formData.append('password', credentials.password);

    const response = await api.post<AuthResponse>('/auth/login', formData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });

    // Store token in localStorage
    if (response.data.access_token) {
      localStorage.setItem('access_token', response.data.access_token);
    }

    return response.data;
  },

  async getCurrentUser(): Promise<User> {
    const response = await api.get<User>('/auth/me');
    return response.data;
  },

  logout() {
    localStorage.removeItem('access_token');
  },
};

// ==========================================
// Rooms APIs
// ==========================================

export const roomsAPI = {
  async getAll(): Promise<Room[]> {
    const response = await api.get<Room[]>('/rooms/');
    return response.data;
  },

  async getById(id: number): Promise<Room> {
    const response = await api.get<Room>(`/rooms/${id}`);
    return response.data;
  },

  async create(data: RoomCreate): Promise<Room> {
    const response = await api.post<Room>('/rooms/', data);
    return response.data;
  },

  async update(id: number, data: RoomUpdate): Promise<Room> {
    const response = await api.patch<Room>(`/rooms/${id}`, data);
    return response.data;
  },

  async delete(id: number): Promise<void> {
    await api.delete(`/rooms/${id}`);
  },
};

// ==========================================
// Messages APIs
// ==========================================

export const messagesAPI = {
  async getByRoom(roomId: number, limit = 50, skip = 0): Promise<Message[]> {
    const response = await api.get<Message[]>(`/rooms/${roomId}/messages`, {
      params: { limit, skip },
    });
    return response.data;
  },

  async getById(id: number): Promise<Message> {
    const response = await api.get<Message>(`/messages/${id}`);
    return response.data;
  },

  async create(roomId: number, data: MessageCreate): Promise<Message> {
    const response = await api.post<Message>(`/rooms/${roomId}/messages`, data);
    return response.data;
  },

  async delete(id: number): Promise<void> {
    await api.delete(`/messages/${id}`);
  },
};

// ==========================================
// Notes APIs
// ==========================================

export const notesAPI = {
  async getByRoom(roomId: number, limit = 100, skip = 0): Promise<Note[]> {
    const response = await api.get<Note[]>(`/rooms/${roomId}/notes`, {
      params: { limit, skip },
    });
    return response.data;
  },

  async getById(id: number): Promise<Note> {
    const response = await api.get<Note>(`/notes/${id}`);
    return response.data;
  },

  async create(roomId: number, data: NoteCreate): Promise<Note> {
    const response = await api.post<Note>(`/rooms/${roomId}/notes`, data);
    return response.data;
  },

  async update(id: number, data: NoteUpdate): Promise<Note> {
    const response = await api.patch<Note>(`/notes/${id}`, data);
    return response.data;
  },

  async delete(id: number): Promise<void> {
    await api.delete(`/notes/${id}`);
  },
};

// Export the axios instance for direct use if needed
export default api;
