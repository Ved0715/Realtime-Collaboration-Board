/**
 * TypeScript types and interfaces for the application
 */

// User types
export interface User {
  id: number;
  email: string;
  full_name: string | null;
  is_active: boolean;
}

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface RegisterData {
  email: string;
  password: string;
  full_name?: string;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
}

// Room types
export interface Room {
  id: number;
  name: string;
  description: string | null;
  created_by: number;
  created_at: string;
}

export interface RoomCreate {
  name: string;
  description?: string;
}

export interface RoomUpdate {
  name?: string;
  description?: string;
}

// Message types
export interface Message {
  id: number;
  content: string;
  room_id: number;
  user_id: number;
  created_at: string;
}

export interface MessageCreate {
  content: string;
}

// Note types
export interface Note {
  id: number;
  content: string;
  position_x: number;
  position_y: number;
  color: string;
  room_id: number;
  user_id: number;
  created_at: string;
  updated_at: string;
}

export interface NoteCreate {
  content: string;
  position_x?: number;
  position_y?: number;
  color?: string;
}

export interface NoteUpdate {
  content?: string;
  position_x?: number;
  position_y?: number;
  color?: string;
}

// WebSocket message types
export type WSMessageType = 'message' | 'note' | 'typing' | 'join' | 'leave' | 'ping' | 'pong' | 'error';

export interface WSMessage {
  type: WSMessageType;
  data: any;
  user_id?: number;
  user_email?: string;
  user_name?: string;
  room_id?: number;
  timestamp: string;
}

export interface WSJoinData {
  user_id: number;
  user_email: string;
  user_name: string;
  room_id: number;
  active_users: number;
}

export interface WSLeaveData {
  user_id: number;
  user_email: string;
  user_name: string;
  room_id: number;
  active_users: number;
}

export interface WSMessageData {
  id?: number;
  content: string;
  user?: User;
}

export interface WSNoteData extends Note {
  action: 'create' | 'update' | 'delete';
}

export interface WSTypingData {
  user: string;
  is_typing: boolean;
}

// API Error types
export interface APIError {
  detail: string | { loc: string[]; msg: string; type: string }[];
}
